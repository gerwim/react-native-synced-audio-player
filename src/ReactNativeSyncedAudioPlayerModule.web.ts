import { registerWebModule, NativeModule } from 'expo';

import { ReactNativeSyncedAudioPlayerModuleEvents } from './ReactNativeSyncedAudioPlayer.types';

class ReactNativeSyncedAudioPlayerModule extends NativeModule<ReactNativeSyncedAudioPlayerModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ReactNativeSyncedAudioPlayerModule);
