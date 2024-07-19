from app import db

class AudioFile(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(150), nullable=False)
    user_id = db.Column(db.Integer, nullable=False)
    upload_time = db.Column(db.DateTime, nullable=False, default=db.func.current_timestamp())
    transcription = db.Column(db.Text, nullable=True)
    vector = db.Column(db.ARRAY(db.Float), nullable=True)

class TextFile(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(150), nullable=False)
    user_id = db.Column(db.Integer, nullable=False)
    upload_time = db.Column(db.DateTime, nullable=False, default=db.func.current_timestamp())
    content = db.Column(db.Text, nullable=False)
    vector = db.Column(db.ARRAY(db.Float), nullable=True)