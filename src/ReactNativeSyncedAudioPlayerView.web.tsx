import * as React from 'react';

import { ReactNativeSyncedAudioPlayerViewProps } from './ReactNativeSyncedAudioPlayer.types';

export default function ReactNativeSyncedAudioPlayerView(props: ReactNativeSyncedAudioPlayerViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
