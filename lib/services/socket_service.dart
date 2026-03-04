import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/api_client.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _requestSocket;
  IO.Socket? _trackingSocket;

  // Streams for /requests namespace
  final _requestNewController = StreamController<ServiceRequest>.broadcast();
  final _requestUpdatedController = StreamController<ServiceRequest>.broadcast();
  final _requestTakenController = StreamController<String>.broadcast(); // Yields requestId

  // Streams for /tracking namespace
  final _mechanicLocationController = StreamController<LatLng>.broadcast();

  // Public getters for streams
  Stream<ServiceRequest> get onRequestNew => _requestNewController.stream;
  Stream<ServiceRequest> get onRequestUpdated => _requestUpdatedController.stream;
  Stream<String> get onRequestTaken => _requestTakenController.stream;
  Stream<LatLng> get onMechanicLocation => _mechanicLocationController.stream;

  bool get isConnected => 
      (_requestSocket?.connected ?? false) || (_trackingSocket?.connected ?? false);

  /// Connect to both namespaces
  void connect(String token) {
    if (isConnected) return;

    final baseUrl = ApiClient.baseUrl;

    // Connect to /requests namespace
    _requestSocket = IO.io('$baseUrl/requests', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 10,
    });

    // Connect to /tracking namespace
    _trackingSocket = IO.io('$baseUrl/tracking', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'extraHeaders': {'Authorization': 'Bearer $token'},
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

    socket.on('request:new', (data) {
      try {
        print('[SocketService] Received request:new');
        final request = ServiceRequest.fromJson(data);
        _requestNewController.add(request);
      } catch (e) {
        print('[SocketService] Error parsing request:new - $e');
      }
    });

    socket.on('request:updated', (data) {
      try {
        print('[SocketService] Received request:updated');
        final request = ServiceRequest.fromJson(data);
        _requestUpdatedController.add(request);
      } catch (e) {
        print('[SocketService] Error parsing request:updated - $e');
      }
    });

    socket.on('request:taken', (data) {
      try {
        final requestId = data['id']?.toString() ?? data['requestId']?.toString() ?? '';
        print('[SocketService] Received request:taken for $requestId');
        if (requestId.isNotEmpty) {
          _requestTakenController.add(requestId);
        }
      } catch (e) {
        print('[SocketService] Error parsing request:taken - $e');
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

    socket.on('mechanic:location', (data) {
      try {
        print('[SocketService] Received mechanic:location');
        final lat = double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0;
        final lng = double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          _mechanicLocationController.add(LatLng(lat, lng));
        }
      } catch (e) {
        print('[SocketService] Error parsing mechanic:location - $e');
      }
    });
  }

  /// Join a specific request room (on /requests namespace)
  void joinRoom(String requestId) {
    if (requestId.isEmpty) return;
    print('[SocketService] Emitting joinRoom: $requestId');
    _requestSocket?.emit('joinRoom', requestId);
    _trackingSocket?.emit('joinRoom', requestId); // Assuming tracking also uses rooms
  }

  /// Leave a specific request room
  void leaveRoom(String requestId) {
    if (requestId.isEmpty) return;
    print('[SocketService] Emitting leaveRoom: $requestId');
    _requestSocket?.emit('leaveRoom', requestId);
    _trackingSocket?.emit('leaveRoom', requestId);
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
