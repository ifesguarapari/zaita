# Zaíta

Protótipo de jogo narrativo 2D inspirado no conto _Zaíta esqueceu de guardar os brinquedos_, de Conceição Evaristo. A proposta é explorar memória, infância e vulnerabilidade social por meio de uma busca simples pelos becos de uma favela representada como labirinto.

Nesta primeira versão não há NPCs, inimigos, combate ou representação explícita de violência. O foco está na exploração e nos pequenos textos revelados ao recolher brinquedos e objetos da infância.

## Como executar

1. Abra a pasta do projeto no Godot 4.6.
2. Execute a cena principal com `F6` ou o projeto com `F5`.
3. Clique em **Começar**.
4. Use o controle touch para caminhar em oito direções.
5. Recolha todos os objetos para concluir a rodada.

Para executar o smoke test permanente:

```bash
/home/walber/godot/Godot_v4.6.2-stable_linux.x86_64 \
  --headless --path /home/walber/src/zaita \
  --script res://tests/RuntimeSmokeTest.gd
```

## Estrutura

- `scenes/Main.tscn`: cena principal, labirinto, interface e fluxo da partida.
- `scenes/Player.tscn`: personagem com estados `idle` e `run`.
- `scenes/Collectible.tscn`: objeto coletável reutilizável.
- `scenes/PopupMessage.tscn`: popup das lembranças e da conclusão.
- `scenes/StartPopup.tscn`: introdução da partida.
- `scenes/TouchJoystick.tscn`: controle touch analógico quantizado em oito direções.
- `scripts/MazeGenerator.gd`: geração aleatória do labirinto conectado com `TileMapLayer`.
- `scripts/ColorFocusOverlay.gd`: filtro radial que preserva a cor perto de Zaíta e leva o restante do mundo para cinza claro.
- `tests/RuntimeSmokeTest.gd`: validação headless permanente do mapa e da coleta.
- `assets/tiles/zaita-tileset.png`: catálogo visual processado em tempo de execução para compor ruas, casas e detalhes.
- `assets/textures/clay.svg`: textura de barro usada sobre as ruas para compor o chão caminhável.
- `assets/sprites/zaita-*.png`: folhas de animação da personagem, recortadas conforme os JSONs correspondentes.
- `assets/images/zaita-collectibles.png`: catálogo transparente dos objetos coletáveis.

## Personalização

Selecione o nó `MazeGenerator` dentro de `scenes/Main.tscn` para alterar no Inspetor:

- `map_width` e `map_height`: tamanho do mapa;
- `tile_size`: tamanho visual dos tiles;
- `collectible_count`: quantidade de objetos;
- `random_seed`: semente fixa para repetir um labirinto, ou `0` para variar a cada rodada.

Um novo labirinto é gerado ao clicar em **Começar** e ao clicar em **Jogar novamente** no popup final.

Os textos dos popups ficam agrupados em `scripts/Main.gd`. O código também contém comentários `TODO` indicando os pontos planejados para efeitos sonoros e fases futuras.

As seções selecionadas do catálogo `zaita-tileset.png` são recortadas em tempo de execução. O mapa padrão mede `50x50`: o primeiro piso forma a base nítida das ruas largas, enquanto uma textura contínua de `assets/textures/clay.svg` cria o chão de barro por cima; pisos também aparecem nas bordas e em praças; casas, fachadas, telhados, paredes e escadas preenchem as quadras. Objetos urbanos e colecionáveis são sorteados apenas sobre as ruas.
