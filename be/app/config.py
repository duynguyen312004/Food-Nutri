import os
from dotenv import load_dotenv


load_dotenv()
class Config:
    # Flask-SQLAlchemy sẽ dùng biến này để kết nối
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    FIREBASE_CREDENTIALS    = os.getenv('FIREBASE_CREDENTIALS')
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
