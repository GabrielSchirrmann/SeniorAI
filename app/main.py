from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from core.ai import perguntar_ai, resetar_conversa
import os
import platform
import webbrowser
import subprocess

app = FastAPI()

# Permite o Flutter se comunicar com o backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class Mensagem(BaseModel):
    mensagem: str

def coletar_ambiente():
    """Coleta informações do ambiente do usuário automaticamente."""
    ambiente = {}

    # Sistema operacional
    ambiente["sistema_operacional"] = platform.system() + " " + platform.release()

    # Navegador padrão
    try:
        browser = webbrowser.get().name
        ambiente["navegador"] = browser
    except:
        ambiente["navegador"] = "desconhecido"

    # Volume atual (Windows)
    try:
        from ctypes import cast, POINTER
        from comtypes import CLSCTX_ALL
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        volume = cast(interface, POINTER(IAudioEndpointVolume))
        mudo = volume.GetMute()
        nivel = int(volume.GetMasterVolumeLevelScalar() * 100)
        ambiente["volume"] = f"{nivel}%" 
        ambiente["mudo"] = "sim" if mudo else "não"
    except:
        ambiente["volume"] = "desconhecido"
        ambiente["mudo"] = "desconhecido"

    return ambiente

@app.get("/")
def raiz():
    return {"status": "SeniorAI backend rodando!"}

@app.post("/perguntar")
def perguntar(body: Mensagem):
    ambiente = coletar_ambiente()

    # Monta contexto do ambiente para a AI
    contexto = f"""
    Informações do ambiente do usuário:
    - Sistema operacional: {ambiente['sistema_operacional']}
    - Navegador padrão: {ambiente['navegador']}
    - Volume atual: {ambiente['volume']}
    - Mudo: {ambiente['mudo']}
    
    Pergunta do usuário: {body.mensagem}
    """

    resposta = perguntar_ai(contexto)

# Fala a resposta em voz alta
    from services.voice import falar
    falar(resposta)

    return {"resposta": resposta, "ambiente": ambiente}

@app.post("/ouvir")
def ouvir():
    """Ativa o microfone e retorna o texto falado pelo usuário."""
    from services.voice import ouvir_usuario
    texto = ouvir_usuario()
    if texto:
        return {"texto": texto, "sucesso": True}
    else:
        return {"texto": "", "sucesso": False}

@app.post("/resetar")
def resetar():
    resetar_conversa()
    return {"status": "Conversa reiniciada!"}