from flask import Blueprint, request, jsonify
from app import db
from app.models import AudioFile, TextFile

main = Blueprint('main', __name__)

@main.route('/upload/audio', methods=['POST'])
def upload_audio():
    data = request.get_json()
    new_file = AudioFile(
        filename=data['filename'],
        user_id=data['userId'],
        transcription=data.get('transcription'),
        vector=data.get('vector')
    )
    db.session.add(new_file)
    db.session.commit()
    return jsonify({'message': 'Audio file added', 'file': new_file.id}), 201

@main.route('/upload/text', methods=['POST'])
def upload_text():
    data = request.get_json()
    new_file = TextFile(
        filename=data['filename'],
        user_id=data['userId'],
        content=data['content'],
        vector=data.get('vector')
    )
    db.session.add(new_file)
    db.session.commit()
    return jsonify({'message': 'Text file added', 'file': new_file.id}), 201

@main.route('/audiofile/<int:id>', methods=['GET'])
def get_audio_file(id):
    audio_file = AudioFile.query.get_or_404(id)
    return jsonify({
        'id': audio_file.id,
        'filename': audio_file.filename,
        'user_id': audio_file.user_id,
        'upload_time': audio_file.upload_time,
        'transcription': audio_file.transcription,
        'vector': audio_file.vector
    })

@main.route('/textfile/<int:id>', methods=['GET'])
def get_text_file(id):
    text_file = TextFile.query.get_or_404(id)
    return jsonify({
        'id': text_file.id,
        'filename': text_file.filename,
        'user_id': text_file.user_id,
        'upload_time': text_file.upload_time,
        'content': text_file.content,
        'vector': text_file.vector
    })

@main.route('/audiofile/<int:id>', methods=['PUT'])
def update_audio_file(id):
    data = request.get_json()
    audio_file = AudioFile.query.get_or_404(id)
    audio_file.filename = data.get('filename', audio_file.filename)
    audio_file.transcription = data.get('transcription', audio_file.transcription)
    audio_file.vector = data.get('vector', audio_file.vector)
    db.session.commit()
    return jsonify({'message': 'Audio file updated', 'file': audio_file.id})

@main.route('/textfile/<int:id>', methods=['PUT'])
def update_text_file(id):
    data = request.get_json()
    text_file = TextFile.query.get_or_404(id)
    text_file.filename = data.get('filename', text_file.filename)
    text_file.content = data.get('content', text_file.content)
    text_file.vector = data.get('vector', text_file.vector)
    db.session.commit()
    return jsonify({'message': 'Text file updated', 'file': text_file.id})

@main.route('/audiofile/<int:id>', methods=['DELETE'])
def delete_audio_file(id):
    audio_file = AudioFile.query.get_or_404(id)
    db.session.delete(audio_file)
    db.session.commit()
    return jsonify({'message': 'Audio file deleted'})

@main.route('/textfile/<int:id>', methods=['DELETE'])
def delete_text_file(id):
    text_file = TextFile.query.get_or_404(id)
    db.session.delete(text_file)
    db.session.commit()
    return jsonify({'message': 'Text file deleted'})