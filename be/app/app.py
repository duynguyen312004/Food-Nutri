from flask import Flask, send_from_directory
from config import Config
from extensions import db, init_firebase
from user.routes import user_bp
from logs.routes import logs_bp
from food.routes import food_bp
from exercise.routes import exercise_bp



def create_app():
    app = Flask(__name__, static_url_path='/static', static_folder='static')
    
    app.config.from_object(Config)

    # Khởi tạo các phần mở rộng
    db.init_app(app)
    init_firebase(app)

    app.register_blueprint(user_bp)
    app.register_blueprint(logs_bp)
    app.register_blueprint(exercise_bp)
    app.register_blueprint(food_bp)

    @app.route('/static/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory('static/uploads', filename)

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)