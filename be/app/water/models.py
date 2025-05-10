from extensions import db

class WaterLog(db.Model):
    __tablename__ = 'water_log'
    water_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    intake_ml = db.Column(db.Integer, nullable=False)
    logged_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
