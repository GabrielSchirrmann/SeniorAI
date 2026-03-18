import os
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_PROMPT = """
Você é um assistente tecnológico especializado em ajudar idosos.
Suas respostas devem seguir OBRIGATORIAMENTE essas regras:

1. Dê APENAS UM passo por vez, nunca o tutorial completo
2. Use linguagem simples, sem termos técnicos
3. Seja gentil, paciente e encorajador
4. Ao final de cada passo, SEMPRE pergunte: "Conseguiu realizar esse passo? (Sim/Não)"
5. Se o idoso disser "Não", explique o mesmo passo de forma mais simples
6. Use frases curtas e diretas

Exemplo de resposta correta:
"Passo 1: Clique no botão com o desenho de alto-falante no canto inferior direito da tela.
Conseguiu realizar esse passo? (Sim/Não)"
"""

historico = []

def perguntar_ai(mensagem_usuario: str) -> str:
    historico.append({
        "role": "user",
        "content": mensagem_usuario
    })

    resposta = client.messages.create(
        model="claude-opus-4-20250514",
        max_tokens=1024,
        system=SYSTEM_PROMPT,
        messages=historico
    )

    texto_resposta = resposta.content[0].text

    historico.append({
        "role": "assistant",
        "content": texto_resposta
    })

    return texto_resposta

def resetar_conversa():
    historico.clear()