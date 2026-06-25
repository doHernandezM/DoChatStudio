# DoChatStudio

DoChatStudio is a document-based SwiftUI application for running local large
language models and vision-language models on Apple hardware. It uses Apple's
MLX framework for inference and Hugging Face model repositories for model
discovery and downloads.

Each conversation is a native document rather than an entry in a shared chat
database. A document stores its message history, system prompt, selected model,
generation settings, and visual preferences, so different chats can be saved,
copied, and reopened as independent workspaces.

## What the app does

- Runs supported LLM and VLM models locally through MLX.
- Streams generated tokens into the conversation as they are produced.
- Saves conversations as `.doChat` documents.
- Downloads and manages models from the `mlx-community` organization on
  Hugging Face.
- Supports built-in model configurations and user-added model repositories.
- Accepts image and video attachments when the selected model supports vision.
- Exposes generation controls including maximum tokens, temperature, and
  top-p sampling.
- Displays generation metadata such as token counts, generation time, and
  tokens per second.
- Tracks active, cached, and peak GPU memory during generation.
- Provides per-document appearance controls for interface, assistant, user,
  and background colors.
- Handles generation cancellation, model download cancellation, and safe
  document termination.
- Includes StoreKit purchase, restore, entitlement, revocation, and feature
  gating flows for Studio features.

## How it is built

The application is organized around a few cooperating layers:

- `DoChatStudioDocument` implements `FileDocument` and serializes the complete
  chat workspace to JSON-backed `.doChat` files.
- `ChatModel` owns the conversation, prompt, attachments, selected model,
  generation parameters, performance samples, and generation lifecycle.
- `MLXService` converts application messages into MLX chat input and performs
  asynchronous LLM or VLM generation.
- `ModelModel` handles model configuration, local storage, Hugging Face
  downloads, progress, caching, deletion, and model state.
- SwiftUI views provide the conversation, inspector, model manager,
  configuration controls, performance charts, and document toolbar.
- `PurchaseManager` and `EntitlementManager` implement the StoreKit 2
  entitlement flow.

Generation is streamed through an asynchronous sequence. Output is buffered
and applied to the interface at roughly 30 frames per second, avoiding a full
view update for every token. Cancellation waits for the generation task to
drain before resetting model and document state. On macOS, completed or
cancelled generations trigger a document save.

## Model support

The current built-in catalog includes configurations from the Phi, Llama,
Qwen, SmolLM, and SmolVLM families. Both text-only and vision-language models
are represented.

Additional models can be added with either:

```text
mlx-community/Model-Name
```

or:

```text
https://huggingface.co/mlx-community/Model-Name
```

Custom model records are persisted locally. Security-scoped bookmarks are used
where required so the app can restore access to model directories after
relaunching.

Model weights are not included in this repository. They are downloaded
separately and remain subject to the license published by each model's author.

## Requirements

- macOS 26, iOS 26, or visionOS 26 as currently configured in the Xcode project
- Xcode with the corresponding platform SDKs
- Apple silicon for MLX inference
- Internet access for the initial Swift package resolution and model downloads

The MLX GPU APIs used by the app are unavailable in the simulator, so model
generation and GPU performance sampling are disabled there. Run on compatible
Apple silicon hardware to exercise the inference path.

## Dependencies

The Xcode project resolves these Swift packages:

- [mlx-swift](https://github.com/ml-explore/mlx-swift)
- [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples)
- [swift-transformers](https://github.com/huggingface/swift-transformers)
- `FlexView`, currently referenced as a local Swift package at
  `../../../FlexView`

The local `FlexView` package must exist at the configured relative path before
the project can build. If your checkout uses a different layout, update the
local package reference in Xcode.

## Building

1. Open `DoChatStudio.xcodeproj` in Xcode.
2. Confirm that the local `FlexView` package reference resolves.
3. Allow Xcode to resolve the remote Swift package dependencies.
4. Select the `DoChatStudio` scheme.
5. Choose a compatible Apple silicon destination and build or run.

The project includes unit-test and UI-test targets. StoreKit behavior can be
exercised with `DoChatStudio/doChatStudio.storekit`.

## Project status

DoChatStudio is under active development. Model compatibility depends on the
MLX model factories and on the configuration published with each Hugging Face
repository. Large models may exceed the memory available on a particular
device.

## License

DoChatStudio is licensed under the GNU General Public License, Version 2 only
(`GPL-2.0-only`). See [LICENSE](LICENSE) for the complete terms.

Third-party packages and downloaded model weights retain their own licenses.
