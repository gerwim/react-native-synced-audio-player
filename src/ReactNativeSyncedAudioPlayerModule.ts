import { NativeModule, requireNativeModule } from "expo";

import { AudioSource } from "./ReactNativeSyncedAudioPlayer.types";

declare class ReactNativeSyncedAudioPlayerModule extends NativeModule {
  // PI: number;
  // hello(): string;
  // setValueAsync(value: string): Promise<void>;
  addSound(value: AudioSource): void;
  play(): void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ReactNativeSyncedAudioPlayerModule>(
  "ReactNativeSyncedAudioPlayer",
);

