import { NativeModule, requireNativeModule } from "expo";

import { AudioSource } from "./ReactNativeSyncedAudioPlayer.types";

declare class ReactNativeSyncedAudioPlayerModule extends NativeModule {
  addTrack(value: AudioSource): number;
  currentPosition(): number;
  setPlaybackSpeed(rate: number): void;
  mute(trackIndex: number): void;
  unmute(trackIndex: number): void;
  setVolume(trackIndex: number, volume: number): void;
  play(): void;
  pause(): void;
  stop(): void;
  reset(): void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ReactNativeSyncedAudioPlayerModule>(
  "ReactNativeSyncedAudioPlayer",
);

