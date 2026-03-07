import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/api_client.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _requestSocket;
  io.Socket? _trackingSocket;

  // Streams for /requests namespace
  // request:new — slim payload, parse as ServiceRequest with defaults for missing fields
  final _requestNewController = StreamController<ServiceRequest>.broadcast();
  // request:updated — backend sends { requestId, status, timestamp }, NOT a full object
  final _requestUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _requestTakenController =
      StreamController<String>.broadcast(); // Yields requestId

  // Streams for /tracking namespace
  final _mechanicLocationController = StreamController<LatLng>.broadcast();

  // Public getters for streams
  Stream<ServiceRequest> get onRequestNew => _requestNewController.stream;
  Stream<Map<String, dynamic>> get onRequestUpdated =>
      _requestUpdatedController.stream;
  Stream<String> get onRequestTaken => _requestTakenController.stream;
  Stream<LatLng> get onMechanicLocation => _mechanicLocationController.stream;

  bool get isConnected =>
      (_requestSocket?.connected ?? false) ||
      (_trackingSocket?.connected ?? false);

  /// Connect to both namespaces
  void connect(String token) {
    if (isConnected) return;

    final baseUrl = ApiClient.baseUrl;

    // Connect to /requests namespace — token via query param
    _requestSocket = io.io('$baseUrl/requests', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'token': token},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 10,
    });

    // Connect to /tracking namespace — token via query param
    _trackingSocket = io.io('$baseUrl/tracking', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'token': token},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 10,
    });

    _setupRequestListeners();
    _setupTrackingListeners();
  }

  void _setupRequestListeners() {
    final socket = _requestSocket;
    if (socket == null) return;

    socket.onConnect((_) {
      print('[SocketService] Connected to /requests namespace');
    });

    socket.onDisconnect((_) {
      print('[SocketService] Disconnected from /requests namespace');
    });

    socket.onConnectError((err) {
      print('[SocketService] /requests connect error: $err');
    });

    // Backend custom events for connection status
    socket.on('connection:success', (data) {
      print(
        '[SocketService] /requests connection:success — ${data['message']} (socketId: ${data['socketId']})',
      );
    });

    socket.on('connection:error', (data) {
      print('[SocketService] /requests connection:error — ${data['error']}');
    });

    // request:new — slim payload from backend (no driverName, no provider fields)
    // { id, description, location, latitude, longitude, serviceType, createdAt }
    socket.on('request:new', (data) {
      try {
        print('[SocketService] Received request:new: $data');
        // Parse as ServiceRequest — fromJson handles missing fields gracefully
        final request = ServiceRequest.fromJson(data as Map<String, dynamic>);
        _requestNewController.add(request);
      } catch (e) {
        print('[SocketService] Error parsing request:new — $e');
      }
    });

    // request:updated — lightweight payload: { requestId, status, timestamp }
    // NOT a full ServiceRequest — pass raw map to state manager
    socket.on('request:updated', (data) {
      try {
        print('[SocketService] Received request:updated: $data');
        _requestUpdatedController.add(Map<String, dynamic>.from(data as Map));
      } catch (e) {
        print('[SocketService] Error parsing request:updated — $e');
      }
    });

    // request:taken — { requestId }
    socket.on('request:taken', (data) {
      try {
        final requestId = data['requestId']?.toString() ?? '';
        print('[SocketService] Received request:taken for $requestId');
        if (requestId.isNotEmpty) {
          _requestTakenController.add(requestId);
        }
      } catch (e) {
        print('[SocketService] Error parsing request:taken — $e');
      }
    });
  }

  void _setupTrackingListeners() {
    final socket = _trackingSocket;
    if (socket == null) return;

    socket.onConnect((_) {
      print('[SocketService] Connected to /tracking namespace');
    });

    socket.onDisconnect((_) {
      print('[SocketService] Disconnected from /tracking namespace');
    });

    socket.onConnectError((err) {
      print('[SocketService] /tracking connect error: $err');
    });

    // Backend custom events for connection status
    socket.on('connection:success', (data) {
      print(
        '[SocketService] /tracking connection:success — ${data['message']}',
      );
    });

    socket.on('connection:error', (data) {
      print('[SocketService] /tracking connection:error — ${data['error']}');
    });

    // mechanic:location:updated — { lat, lng, timestamp }
    socket.on('mechanic:location:updated', (data) {
      try {
        final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
        final lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
          _mechanicLocationController.add(LatLng(lat, lng));
        }
      } catch (e) {
        print('[SocketService] Error parsing mechanic:location:updated — $e');
      }
    });

    // mechanic:current-location — response to request:current-location
    socket.on('mechanic:current-location', (data) {
      try {
        if (data == null) return;
        final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
        final lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
          _mechanicLocationController.add(LatLng(lat, lng));
        }
      } catch (e) {
        print('[SocketService] Error parsing mechanic:current-location — $e');
      }
    });
  }

  /// Send mechanic location update (provider side)
  void sendLocationUpdate(String requestId, double lat, double lng) {
    _trackingSocket?.emit('mechanic:location:update', {
      'requestId': requestId,
      'lat': lat,
      'lng': lng,
    });
  }

  /// Join a request tracking room (both driver and mechanic should call this)
  void joinRequest(String requestId) {
    _trackingSocket?.emit('request:join', {'requestId': requestId});
    print('[SocketService] Joining tracking room for request: $requestId');
  }

  /// Leave a request tracking room
  void leaveRequest(String requestId) {
    _trackingSocket?.emit('request:leave', {'requestId': requestId});
    print('[SocketService] Leaving tracking room for request: $requestId');
  }

  /// Request the current/last known mechanic location for a request
  void requestCurrentLocation(String requestId) {
    _trackingSocket?.emit('request:current-location', {'requestId': requestId});
  }

  /// Disconnect all sockets
  void disconnect() {
    print('[SocketService] Disconnecting sockets');
    _requestSocket?.disconnect();
    _requestSocket?.dispose();
    _requestSocket = null;

    _trackingSocket?.disconnect();
    _trackingSocket?.dispose();
    _trackingSocket = null;
  }
}
