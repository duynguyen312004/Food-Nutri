from functools import wraps
from flask import request, jsonify, g, current_app as app
from firebase_admin import auth as fb_auth
from user.services import upsert_user_from_firebase

def firebase_required():
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            # 1. Lấy header Authorization
            auth_header = request.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return jsonify({'error': 'Missing or invalid Authorization header'}), 401

            # 2. Tách idToken
            id_token = auth_header.split(' ', 1)[1]
            try:
                # 3. Verify token với Firebase Admin SDK
                decoded = fb_auth.verify_id_token(id_token, clock_skew_seconds=60)
            except Exception:
                return jsonify({'error': 'Invalid Firebase ID token'}), 401

            # 4. Upsert hoặc tạo mới bản ghi User trong DB
            #    upsert_user_from_firebase sẽ đọc các trường như uid, email, name, picture
            #    rồi trả về object User của SQLAlchemy
            user = upsert_user_from_firebase(decoded)

            # 5. Gán user vào flask.g để các hàm điều khiển (view) truy cập dễ dàng
            g.current_user = user

            # 6. Tiến hành gọi hàm view gốc
            return f(*args, **kwargs)
        return wrapper
    return decorator
