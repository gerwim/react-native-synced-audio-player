// export { default } from "./ReactNativeSyncedAudioPlayerModule";
// export * from "./ReactNativeSyncedAudioPlayer.types";

import { AudioSource } from "./ReactNativeSyncedAudioPlayer.types";
import ReactNativeSyncedAudioPlayerModule from "./ReactNativeSyncedAudioPlayerModule";
import { resolveSource } from "./utils/resolveSource";

export function addTrack(value: AudioSource): number {
  const source = resolveSource(value);
  return ReactNativeSyncedAudioPlayerModule.addTrack(source);
}

export function play(): void {
  ReactNativeSyncedAudioPlayerModule.play();
}

export function pause(): void {
  ReactNativeSyncedAudioPlayerModule.pause();
}

export function stop(): void {
  ReactNativeSyncedAudioPlayerModule.stop();
}

export function setPlaybackSpeed(rate: number): void {
  ReactNativeSyncedAudioPlayerModule.setPlaybackSpeed(rate);
}

export function reset(): void {
  ReactNativeSyncedAudioPlayerModule.reset();
}

export function currentPosition(): number {
  return ReactNativeSyncedAudioPlayerModule.currentPosition();
}

export function mute(trackIndex: number): void {
  ReactNativeSyncedAudioPlayerModule.mute(trackIndex);
}

export function unmute(trackIndex: number): void {
  ReactNativeSyncedAudioPlayerModule.unmute(trackIndex);
}

export function seek(seconds: number): void {
  ReactNativeSyncedAudioPlayerModule.seek(seconds);
}

export function setVolume(trackIndex: number, volume: number): void {
  ReactNativeSyncedAudioPlayerModule.setVolume(trackIndex, volume);
}
