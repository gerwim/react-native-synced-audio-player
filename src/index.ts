// Reexport the native module. On web, it will be resolved to ReactNativeSyncedAudioPlayerModule.web.ts
// and on native platforms to ReactNativeSyncedAudioPlayerModule.ts
export { default } from './ReactNativeSyncedAudioPlayerModule';
export { default as ReactNativeSyncedAudioPlayerView } from './ReactNativeSyncedAudioPlayerView';
export * from  './ReactNativeSyncedAudioPlayer.types';
