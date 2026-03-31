import threading
import speech_recognition as sr
import re
import os
import tempfile

# ─── TTS com gTTS (voz do Google) ─────────────────────────────────────────────
def limpar_texto(texto: str) -> str:
    """Remove caracteres que atrapalham a leitura em voz alta."""
    texto = texto.replace('**', '')
    texto = texto.replace('*', '')
    texto = texto.replace('/Não', ', ou não')
    texto = texto.replace('/Sim', ', ou sim')
    texto = texto.replace('(Sim/Não)', 'Sim ou Não?')
    texto = texto.replace('/', ' ')
    texto = texto.replace('#', '')
    texto = texto.replace('_', ' ')
    texto = re.sub(r'\s+', ' ', texto)
    return texto.strip()

def falar(texto: str):
    """Usa gTTS para falar com a voz do Google em português brasileiro."""
    def _falar():
        try:
            from gtts import gTTS
            import pygame

            texto_limpo = limpar_texto(texto)

            # Gera o áudio em arquivo temporário
            tts = gTTS(text=texto_limpo, lang='pt', tld='com.br', slow=False)
            with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as f:
                caminho = f.name
                tts.save(caminho)

            # Reproduz o áudio
            pygame.mixer.init()
            pygame.mixer.music.load(caminho)
            pygame.mixer.music.play()

            # Aguarda terminar
            while pygame.mixer.music.get_busy():
                pygame.time.Clock().tick(10)

            pygame.mixer.music.unload()
            os.remove(caminho)

        except Exception as e:
            print(f"Erro no TTS: {e}")

    thread = threading.Thread(target=_falar)
    thread.daemon = True
    thread.start()

def parar_fala():
    """Para a fala atual."""
    try:
        import pygame
        pygame.mixer.music.stop()
    except:
        pass

# ─── STT (Speech to Text — usuário fala) ──────────────────────────────────────
recognizer = sr.Recognizer()

def ouvir_usuario() -> str:
    """Ouve o microfone e retorna o texto falado pelo usuário."""
    with sr.Microphone() as source:
        print("Ouvindo...")
        recognizer.adjust_for_ambient_noise(source, duration=1)
        try:
            audio = recognizer.listen(source, timeout=8, phrase_time_limit=15)
            texto = recognizer.recognize_google(audio, language='pt-BR')
            print(f"Usuário disse: {texto}")
            return texto
        except sr.WaitTimeoutError:
            return ""
        except sr.UnknownValueError:
            return ""
        except sr.RequestError:
            return ""