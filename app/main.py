from core.ai import perguntar_ai, resetar_conversa

print("=" * 50)
print("   Assistente Tech para Idosos - SeniorAI")
print("=" * 50)
print("Digite seu problema e pressione Enter.")
print("Digite 'sair' para encerrar.\n")

while True:
    problema = input("Você: ")

    if problema.lower() == "sair":
        print("Até logo!")
        break

    if problema.lower() == "reiniciar":
        resetar_conversa()
        print("Conversa reiniciada!\n")
        continue

    resposta = perguntar_ai(problema)
    print(f"\nAssistente: {resposta}\n")
    print("-" * 50)