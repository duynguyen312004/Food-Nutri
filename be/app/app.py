from flask import Flask
from sqlalchemy import text
from config import Config
from extensions import db, init_firebase
from user.routes import user_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Khởi tạo các phần mở rộng
    db.init_app(app)
    init_firebase(app)

    app.register_blueprint(user_bp)

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)