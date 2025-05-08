from flask_sqlalchemy import SQLAlchemy
import firebase_admin
from firebase_admin import credentials, auth as fb_auth

db = SQLAlchemy()

def init_firebase(app):
    cred = credentials.Certificate(app.config['FIREBASE_CREDENTIALS'])
    firebase_admin.initialize_app(cred)
