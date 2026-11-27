# self_hosted_updater example

Start the mock update server from the repo root:

```bash
cd mock_server && npm install && node server.js
```

Then run one of the two apps:

| Command | What it shows |
|---|---|
| `flutter run` | [lib/main.dart](lib/main.dart): the minimal integration. Checks on startup and from a button. |
| `flutter run -t lib/demo.dart` | [lib/demo.dart](lib/demo.dart): the full demo used for the README screenshots. |

Pick the dialog style in the demo with
`--dart-define=DIALOG_STYLE=material` (`material` | `cupertino` | `bottomSheet`).
