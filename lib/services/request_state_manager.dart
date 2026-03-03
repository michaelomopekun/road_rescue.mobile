import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/socket_service.dart';
import 'package:road_rescue/services/driver_service.dart'; // We'll add getActiveRequest
import 'package:road_rescue/services/mechanic_service.dart'; // We'll add getActiveRequest
import 'package:road_rescue/services/token_service.dart';

class RequestStateManager extends ChangeNotifier {
  // Singleton pattern
  static final RequestStateManager _instance = RequestStateManager._internal();
  factory RequestStateManager() => _instance;
  RequestStateManager._internal() {
    _socketService = SocketService();
  }

  late final SocketService _socketService;

  // State
  ServiceRequest? _activeRequest;
  List<ServiceRequest> _pendingRequests = []; // For mechanic broadcasts
  LatLng? _mechanicLocation;
  bool _isLoading = false;
  String? _error;

  // Subscriptions
  StreamSubscription? _requestNewSub;
  StreamSubscription? _requestUpdatedSub;
  StreamSubscription? _requestTakenSub;
  StreamSubscription? _mechanicLocationSub;

  // Getters
  ServiceRequest? get activeRequest => _activeRequest;
  RequestStatus get status => _activeRequest?.status ?? RequestStatus.PENDING;
  List<ServiceRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  LatLng? get mechanicLocation => _mechanicLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveRequest => _activeRequest != null;

  /// Initialize state manager, connect sockets, and load active request
  Future<void> initialize() async {
    _cleanupSubscriptions();

    final token = await TokenService.getToken();
    if (token != null) {
      _socketService.connect(token);
    }

    _setupSubscriptions();
    await loadActiveRequest();
  }

  void _setupSubscriptions() {
    _requestNewSub = _socketService.onRequestNew.listen((request) {
      final role = _getUserRoleSync();
      if (role == 'PROVIDER' && !hasActiveRequest) {
        // Mechanic receives a new broadcast request
        if (!_pendingRequests.any((r) => r.id == request.id)) {
          _pendingRequests.add(request);
          notifyListeners();
        }
      }
    });

    _requestUpdatedSub = _socketService.onRequestUpdated.listen((request) {
      _handleRequestUpdated(request);
    });

    _requestTakenSub = _socketService.onRequestTaken.listen((requestId) {
      // Dismiss pending request if another mechanic took it
      _pendingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
    });

    _mechanicLocationSub = _socketService.onMechanicLocation.listen((location) {
      _mechanicLocation = location;
      notifyListeners();
    });
  }

  void _handleRequestUpdated(ServiceRequest updatedRequest) {
    if (_activeRequest == null) {
      // It's possible we missed the transition, or we just claimed it
      _setActiveRequest(updatedRequest);
      return;
    }

    if (_activeRequest!.id != updatedRequest.id) {
      print('[RequestStateManager] Ignoring update for request ${updatedRequest.id} (active: ${_activeRequest!.id})');
      return;
    }

    // Validate transition
    final currentStatus = _activeRequest!.status;
    final nextStatus = updatedRequest.status;

    if (currentStatus.isValidTransition(nextStatus) || currentStatus == nextStatus) {
      _setActiveRequest(updatedRequest);
    } else {
      print('[RequestStateManager] Invalid status transition: $currentStatus -> $nextStatus');
      // Set it anyway to sync with server, but log the invalid state
      _setActiveRequest(updatedRequest);
    }
  }

  /// Manually set the active request (e.g. after REST call success)
  void setActiveRequest(ServiceRequest request) {
    _setActiveRequest(request);
  }

  void _setActiveRequest(ServiceRequest request) {
    _activeRequest = request;
    
    // If request is cancelled or paid, we stop tracking immediately but keep state for UI
    if (request.status == RequestStatus.CANCELLED || request.status == RequestStatus.PAID) {
      _socketService.leaveRoom(request.id);
      _mechanicLocation = null;
    } else {
      // Ensure we are in the room
      _socketService.joinRoom(request.id);
    }

    // Clear pending requests since we now have an active one
    _pendingRequests.clear();
    
    notifyListeners();
  }

  /// Load active request from backend
  Future<void> loadActiveRequest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final role = await TokenService.getUserRole();
      ServiceRequest? request;

      if (role == 'DRIVER') {
        // Will implement getActiveRequest in DriverService
        request = await DriverService.getActiveRequest(); 
      } else if (role == 'PROVIDER') {
        // Will implement getActiveRequest in MechanicService
        request = await MechanicService.getActiveRequest();
      }

      if (request != null) {
        _setActiveRequest(request);
      } else {
        clearActiveRequest();
      }
    } catch (e) {
      print('[RequestStateManager] Error loading active request: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the active request entirely
  void clearActiveRequest() {
    if (_activeRequest != null) {
      _socketService.leaveRoom(_activeRequest!.id);
    }
    _activeRequest = null;
    _mechanicLocation = null;
    notifyListeners();
  }

  void removePendingRequest(String requestId) {
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  void _cleanupSubscriptions() {
    _requestNewSub?.cancel();
    _requestUpdatedSub?.cancel();
    _requestTakenSub?.cancel();
    _mechanicLocationSub?.cancel();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    _socketService.disconnect();
    super.dispose();
  }

  // Workaround since we can't 'await' in stream listeners easily
  String? _cachedRole;
  Future<void> _primeUserRole() async {
    _cachedRole = await TokenService.getUserRole();
  }
  
  String? _getUserRoleSync() {
    if (_cachedRole == null) {
      _primeUserRole();
    }
    return _cachedRole;
  }
}
