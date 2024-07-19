import sqlite3
import numpy as np
from sentence_transformers import SentenceTransformer
import json

# Initialize the embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Connect to the SQLite database
conn = sqlite3.connect('notes.db')
cursor = conn.cursor()

# Create a new table for embeddings if it doesn't exist
cursor.execute('''
CREATE TABLE IF NOT EXISTS embeddings
(id INTEGER PRIMARY KEY, note_id INTEGER, embedding TEXT)
''')

# Fetch all notes
cursor.execute('SELECT id, content FROM notes')
notes = cursor.fetchall()

# Process each note and store its embedding
for note_id, content in notes:
    # Generate embedding
    embedding = model.encode(content)
    
    # Convert numpy array to list and then to JSON string
    embedding_json = json.dumps(embedding.tolist())
    
    # Store in database
    cursor.execute('INSERT OR REPLACE INTO embeddings (note_id, embedding) VALUES (?, ?)',
                   (note_id, embedding_json))

# Commit changes and close connection
conn.commit()
conn.close()

print("Embeddings created and stored successfully.")