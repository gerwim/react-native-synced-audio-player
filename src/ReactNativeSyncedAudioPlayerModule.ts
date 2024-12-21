import { NativeModule, requireNativeModule } from 'expo';

import { ReactNativeSyncedAudioPlayerModuleEvents } from './ReactNativeSyncedAudioPlayer.types';

declare class ReactNativeSyncedAudioPlayerModule extends NativeModule<ReactNativeSyncedAudioPlayerModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ReactNativeSyncedAudioPlayerModule>('ReactNativeSyncedAudioPlayer');
