import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HttpInterceptor {
  static Future<http.Response> get(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.get(url, headers: requestHeaders);
    
    // Verificar si el token expiró
    if (response.statusCode == 401) {
      await _handleTokenExpiry(context);
      return response;
    }
    
    return response;
  }

  static Future<http.Response> post(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.post(
      url,
      headers: requestHeaders,
      body: body is String ? body : jsonEncode(body),
    );
    
    // Verificar si el token expiró
    if (response.statusCode == 401) {
      await _handleTokenExpiry(context);
      return response;
    }
    
    return response;
  }

  static Future<http.Response> put(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.put(
      url,
      headers: requestHeaders,
      body: body is String ? body : jsonEncode(body),
    );
    
    // Verificar si el token expiró
    if (response.statusCode == 401) {
      await _handleTokenExpiry(context);
      return response;
    }
    
    return response;
  }

  static Future<http.Response> delete(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.delete(url, headers: requestHeaders);
    
    // Verificar si el token expiró
    if (response.statusCode == 401) {
      await _handleTokenExpiry(context);
      return response;
    }
    
    return response;
  }

  static Future<void> _handleTokenExpiry(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.handleTokenExpiry(context);
  }
}
