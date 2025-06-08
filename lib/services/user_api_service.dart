import 'dart:convert';
import 'dart:io'; // Dùng cho SocketException (lỗi kết nối mạng)
import 'dart:async'; // Dùng cho TimeoutException (lỗi quá thời gian yêu cầu)
import 'package:http/http.dart' as http;
import '../models/register.dart';
import '../models/login.dart';
import '../models/user_update.dart'; // Dùng cho updateUserProfile
import '../models/user.dart'; // Dùng để trả về đối tượng User

class UserApiService {
  // Endpoint API cơ sở cho các hoạt động liên quan đến User (bao gồm đăng nhập, đăng ký, cập nhật profile)
  static const String _baseUrl = 'http://localhost:5062/api/User';

  // Thời gian chờ tối đa cho một yêu cầu API
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Hàm helper để tạo headers cho request
  Map<String, String> _getHeaders({String? token, bool isJsonContent = true}) {
    final headers = <String, String>{};
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token'; // Thêm token vào header nếu có
    }
    return headers;
  }

  // Hàm đăng ký người dùng mới
  Future<Map<String, dynamic>> register(RegisterDTO dto) async {
    // Endpoint đăng ký: POST /api/User (chính là _baseUrl)
    final url = Uri.parse(_baseUrl);
    try {
      final response = await http
          .post(
            url,
            headers: _getHeaders(),
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeoutDuration);

      print('Trạng thái đăng ký: ${response.statusCode}');
      print('Nội dung phản hồi đăng ký: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) { // API trả về 201 CreatedAtAction
        if (responseBody is Map<String, dynamic>) {
          // API đăng ký (PostUser) trả về UserDTO (chứa id, name, email, role)
          if (responseBody.containsKey('id') && responseBody.containsKey('email')) {
             // Trả về thông tin user để có thể dùng ngay nếu cần, hoặc chỉ message
             return {'user': responseBody, 'message': 'Đăng ký thành công.'};
          }
          // Nếu API chỉ trả về message (ít khả năng với CreatedAtAction)
          if (responseBody.containsKey('message')) {
             return {'message': responseBody['message']};
          }
        }
        // Fallback nếu responseBody không như mong đợi nhưng status là success
        return {'message': 'Đăng ký thành công. Vui lòng đăng nhập.'};
      } else {
        // API trả về BadRequest với object { "message": "Email đã tồn tại." }
        throw Exception(responseBody['message'] ?? 'Đăng ký thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('Không có kết nối mạng khi đăng ký');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Yêu cầu đăng ký quá thời gian');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } on FormatException catch (e) {
      print('Lỗi giải mã JSON phản hồi đăng ký: $e');
      throw Exception('Dữ liệu phản hồi đăng ký không hợp lệ.');
    } catch (e) {
      print('Ngoại lệ khi đăng ký: $e');
      rethrow;
    }
  }

  // Hàm đăng nhập người dùng
  Future<Map<String, dynamic>> login(LoginDTO dto) async {
    // Endpoint đăng nhập: POST /api/User/login
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http
          .post(
            url,
            headers: _getHeaders(),
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeoutDuration);

      print('Trạng thái đăng nhập: ${response.statusCode}');
      print('Nội dung phản hồi đăng nhập: ${response.body}');
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // API login trả về LoginResponseDTO { Token, ExpiresIn, UserDTO }
        if (responseBody is Map<String, dynamic> &&
            responseBody.containsKey('token') && // Kiểm tra có token
            (responseBody.containsKey('user') && responseBody['user'] is Map<String,dynamic> && (responseBody['user'] as Map<String,dynamic>).containsKey('id')) // Kiểm tra có user object và user.id
            ) {
          // Không cần phải tự tạo userMap nữa nếu API trả về đúng cấu trúc LoginResponseDTO
          // final userMap = {
          //   'id': responseBody['id'], // Nếu user data nằm phẳng (không khuyến khích nếu đã có user object)
          //   'name': responseBody['name'],
          //   'email': responseBody['email'],
          //   'role': responseBody['role'],
          // };
          // responseBody['user'] = userMap; // Chỉ làm nếu API không trả về user object lồng nhau
          return responseBody;
        } else {
          throw Exception('Phản hồi đăng nhập không chứa đủ thông tin token hoặc người dùng hợp lệ.');
        }
      } else {
        // API trả về 401 Unauthorized với object { "message": "Email không tồn tại!" } hoặc { "message": "Sai mật khẩu!" }
        throw Exception(responseBody['message'] ?? 'Đăng nhập thất bại (mã: ${response.statusCode}).');
      }
    } on SocketException {
      print('Không có kết nối mạng khi đăng nhập');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Yêu cầu đăng nhập quá thời gian');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } on FormatException catch (e) {
      print('Lỗi giải mã JSON phản hồi đăng nhập: $e');
      throw Exception('Dữ liệu phản hồi đăng nhập không hợp lệ.');
    } catch (e) {
      print('Ngoại lệ khi đăng nhập: $e');
      rethrow;
    }
  }

  // Hàm cập nhật thông tin người dùng
  Future<bool> updateUserProfile(
    int userId,
    UserUpdate userUpdateData, {
    String? oldPassword,
    String? newPassword,
    required String token,
  }) async {
    // Endpoint cập nhật user: PUT /api/User/{id}
    final url = Uri.parse('$_baseUrl/$userId');
    print('UserApiService: Cập nhật profile cho userId: $userId, token: $token');
    try {
      Map<String, dynamic> requestBody = userUpdateData.toJson();

      // API (PutUser) yêu cầu OldPassword nếu NewPassword được cung cấp.
      // Logic này nên được xử lý ở tầng gọi (UI/AuthProvider) để đảm bảo oldPassword được gửi kèm.
      if (newPassword != null) { // Nếu có mật khẩu mới
        if (oldPassword == null) {
          // API sẽ từ chối nếu oldPassword là null và newPassword có giá trị.
          // Có thể ném lỗi ở đây hoặc để API xử lý.
          print('UserApiService: Cảnh báo - NewPassword được cung cấp nhưng OldPassword là null. API có thể từ chối.');
          // throw ArgumentError('Cần cung cấp mật khẩu cũ để đặt mật khẩu mới.');
        }
        requestBody['oldPassword'] = oldPassword; // Gửi cả hai nếu newPassword có
        requestBody['newPassword'] = newPassword;
      }
      // Xóa bỏ điều kiện phức tạp không cần thiết:
      // } else if (newPassword != null && oldPassword == null && userUpdateData.toJson().isEmpty) {
      //    print('UserApiService: Đang cố gắng đặt mật khẩu mới mà không có mật khẩu cũ và không có thông tin khác thay đổi.');
      //    requestBody['newPassword'] = newPassword;
      // }

      if (requestBody.isEmpty) {
        print('UserApiService: Không có dữ liệu để cập nhật.');
        return true; // Không có gì thay đổi, coi như thành công
      }
      
      print('UserApiService: Request body cập nhật: ${json.encode(requestBody)}');

      final response = await http
          .put(
            url,
            headers: _getHeaders(token: token),
            body: json.encode(requestBody),
          )
          .timeout(_timeoutDuration);

      print('Trạng thái cập nhật profile: ${response.statusCode}');
      print('Nội dung phản hồi cập nhật profile: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content là thành công
        return true;
      } else {
        // API có thể trả về 400 BadRequest với { "message": "..." }
        // hoặc 401 Unauthorized nếu token không hợp lệ (dù ít khả năng nếu đã qua AuthProvider)
        // hoặc 404 Not Found nếu user ID không tồn tại
        final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(responseBody['message'] ?? 'Cập nhật thông tin thất bại (mã: ${response.statusCode}). Phản hồi: ${response.body}');
      }
    } on SocketException {
      print('Không có kết nối mạng khi cập nhật profile');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Yêu cầu cập nhật profile quá thời gian');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } on FormatException catch (e) {
      print('Lỗi giải mã JSON phản hồi cập nhật profile: $e. Body: ${e.source}');
      throw Exception('Dữ liệu phản hồi cập nhật không hợp lệ.');
    } catch (e) {
      print('Ngoại lệ khi cập nhật profile: $e');
      rethrow;
    }
  }

  // Hàm lấy thông tin chi tiết của người dùng hiện tại (đã đăng nhập)
  Future<User> getCurrentUserDetails(String token) async {
    // QUAN TRỌNG: Endpoint này (`/api/User/me`) cần phải tồn tại ở backend.
    // UserController.cs hiện tại của bạn không có endpoint này.
    // Bạn cần thêm [HttpGet("me")] [Authorize] vào UserController.cs.
    final url = Uri.parse('$_baseUrl/me');
    print('UserApiService: Lấy thông tin người dùng hiện tại, token: $token');
    try {
      final response = await http
          .get(url, headers: _getHeaders(token: token))
          .timeout(_timeoutDuration);

      print('Trạng thái lấy thông tin người dùng hiện tại: ${response.statusCode}');
      print('Nội dung phản hồi lấy thông tin người dùng hiện tại: ${response.body}');
      
      if (response.statusCode == 200) {
         final responseBody = jsonDecode(response.body);
         if (responseBody is Map<String, dynamic>) {
            return User.fromJson(responseBody); // API nên trả về UserDTO
         } else {
            throw Exception('Dữ liệu người dùng trả về không hợp lệ.');
         }
      } else {
        // API có thể trả về 401 Unauthorized nếu token không hợp lệ, hoặc 404 nếu /me không tồn tại
        final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(responseBody['message'] ?? 'Lỗi lấy thông tin người dùng (mã: ${response.statusCode}). Phản hồi: ${response.body}');
      }
    } on SocketException {
      print('Không có kết nối mạng khi lấy thông tin người dùng hiện tại');
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } on TimeoutException {
      print('Yêu cầu lấy thông tin người dùng hiện tại quá thời gian');
      throw Exception('Yêu cầu quá thời gian. Vui lòng thử lại.');
    } on FormatException catch (e) {
      print('Lỗi giải mã JSON phản hồi thông tin người dùng hiện tại: $e. Body: ${e.source}');
      throw Exception('Dữ liệu phản hồi người dùng không hợp lệ.');
    } catch (e) {
      print('Ngoại lệ khi lấy thông tin người dùng hiện tại: $e');
      rethrow;
    }
  }
}