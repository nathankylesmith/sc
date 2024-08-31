# Audio Recording Module Configuration

## Audio Input Settings

1. **Sample Rate**: 8000 Hz (default)
   - Can be dynamically set based on the detected audio codec
   - For PCM16: 16000 Hz
   - For µ-law: 8000 Hz

2. **Bits per Sample**: 
   - Input: 8 bits (default)
   - Output: Always converted to 16 bits for WAV file

3. **Number of Channels**: 1 (Mono)

4. **Audio Codec**: Detected from BLE device
   - Supported codecs: PCM8, PCM16, µ-law8, µ-law16
   - Default: PCM8

## BLE Audio Data Processing

1. **Data Reception**:
   - Receives data packets from BLE characteristic
   - Strips first 3 bytes (header) from each packet
   - Remaining data is treated as raw audio data

2. **Buffer Management**:
   - Maintains an in-memory buffer (`_audioBuffer`)
   - Maximum buffer size: 1MB (1,024,000 bytes)
   - When buffer exceeds max size, data is written to a temporary file on disk

## WAV File Creation

1. **File Naming**: 
   - Format: `audio_[timestamp].wav`
   - Timestamp: milliseconds since epoch

2. **WAV Header**:
   - RIFF header: "RIFF"
   - File size: 36 + data size
   - WAVE header: "WAVE"
   - Format chunk: "fmt "
   - Subchunk1 size: 16 bytes
   - Audio format: 1 (PCM)
   - Number of channels: 1 (Mono)
   - Sample rate: As detected (8000 Hz or 16000 Hz)
   - Byte rate: SampleRate * NumChannels * BytesPerSample
   - Block align: NumChannels * BytesPerSample
   - Bits per sample: 16 (forced)
   - Data chunk: "data"
   - Subchunk2 size: Size of audio data

3. **Audio Data**:
   - Appended after the WAV header
   - If input is 8-bit, each sample is expanded to 16-bit
   - For µ-law, data is decoded to 16-bit PCM before saving

## File Saving Process

1. Create WAV header based on audio settings
2. Combine temporary file data (if any) with in-memory buffer
3. Create final WAV file:
   - Write WAV header (44 bytes)
   - Append audio data
4. Clear audio buffer after saving

## Playback Configuration

1. Uses `just_audio` package for playback
2. Configures audio session for speech playback
3. Reads and logs WAV header and first 20 bytes of audio data for debugging

## Additional Notes

- The module supports real-time recording from BLE devices
- µ-law decoding is implemented but currently not used in the main processing loop
- Duration calculation: (buffer length) / (sample rate * channels * bytes per sample)

This configuration ensures that regardless of the input audio format, the output is always a 16-bit PCM WAV file, which is widely supported for playback on various systems.