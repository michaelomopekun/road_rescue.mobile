import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/socket_service.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
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
  final List<ServiceRequest> _pendingRequests = []; // For mechanic broadcasts
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

    // Prime the user role cache
    await _primeUserRole();

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

    // request:updated now sends { requestId, status, timestamp } — NOT a full ServiceRequest
    _requestUpdatedSub = _socketService.onRequestUpdated.listen((data) {
      _handleRequestUpdated(data);
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

  /// Handle request:updated - backend sends { requestId, status, timestamp }
  void _handleRequestUpdated(Map<String, dynamic> data) {
    final requestId = data['requestId']?.toString() ?? '';
    final statusStr = data['status']?.toString() ?? '';

    if (requestId.isEmpty || statusStr.isEmpty) {
      print('[RequestStateManager] Invalid request:updated payload: $data');
      return;
    }

    final newStatus = RequestStatus.fromString(statusStr);

    // If we have an active request and it matches, update its status
    if (_activeRequest != null && _activeRequest!.id == requestId) {
      print('[RequestStateManager] Updating active request status: ${_activeRequest!.status} → $newStatus');
      _activeRequest = _activeRequest!.copyWith(status: newStatus);

      // Handle terminal states
      if (newStatus == RequestStatus.CANCELLED || newStatus == RequestStatus.PAID) {
        _mechanicLocation = null;
      }

      notifyListeners();

      // For transitions that add new data (QUOTED adds quotation, ACCEPTED adds provider info),
      // re-fetch the full enriched object from the server
      if (newStatus == RequestStatus.ACCEPTED ||
          newStatus == RequestStatus.QUOTED ||
          newStatus == RequestStatus.COMPLETED) {
        _refetchActiveRequest();
      }
    } else if (_activeRequest == null) {
      // We didn't have an active request — this could happen if we just accepted one
      // Fetch the full enriched object
      print('[RequestStateManager] No active request but got update for $requestId. Fetching full state.');
      _refetchActiveRequest();
    } else {
      print('[RequestStateManager] Ignoring update for request $requestId (active: ${_activeRequest!.id})');
    }
  }

  /// Re-fetch the active request from REST to get the full enriched object
  Future<void> _refetchActiveRequest() async {
    try {
      final role = _getUserRoleSync();
      ServiceRequest? request;

      if (role == 'DRIVER') {
        request = await DriverService.getActiveRequest();
      } else if (role == 'PROVIDER') {
        request = await MechanicService.getActiveRequest();
      }

      if (request != null) {
        _activeRequest = request;
        notifyListeners();
      }
    } catch (e) {
      print('[RequestStateManager] Error re-fetching active request: $e');
    }
  }

  /// Manually set the active request (e.g. after REST call success)
  void setActiveRequest(ServiceRequest request) {
    _activeRequest = request;

    // If request is cancelled or paid, stop tracking
    if (request.status == RequestStatus.CANCELLED || request.status == RequestStatus.PAID) {
      _mechanicLocation = null;
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
        request = await DriverService.getActiveRequest();
      } else if (role == 'PROVIDER') {
        request = await MechanicService.getActiveRequest();
      }

      if (request != null) {
        setActiveRequest(request);
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

  // User role caching
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
