import { requireNativeView } from 'expo';
import * as React from 'react';

import { ReactNativeSyncedAudioPlayerViewProps } from './ReactNativeSyncedAudioPlayer.types';

const NativeView: React.ComponentType<ReactNativeSyncedAudioPlayerViewProps> =
  requireNativeView('ReactNativeSyncedAudioPlayer');

export default function ReactNativeSyncedAudioPlayerView(props: ReactNativeSyncedAudioPlayerViewProps) {
  return <NativeView {...props} />;
}
