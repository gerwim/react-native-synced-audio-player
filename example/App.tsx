import Slider from "@react-native-community/slider";
import { useEvent } from "expo";
import { useCallback, useEffect, useRef, useState } from "react";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import {
  addTrack,
  play,
  pause,
  stop,
  reset,
  currentPosition,
  setPlaybackSpeed,
  mute,
  unmute,
  setVolume,
} from "react-native-synced-audio-player";

export default function App() {
  const [currentPos, setCurrentPos] = useState<number>(0);
  const [playbackSpeed, setPlaybackSpeedState] = useState<number>(1.0);
  const [volumes, setVolumes] = useState<number[]>([1.0, 1.0, 1.0, 1.0, 1.0]);
  const [soundTracks, setSoundTracks] = useState<
    { name: string; trackId: number }[]
  >([]);
  const timeoutRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    const interval = setInterval(
      () => setCurrentPos(() => currentPosition()),
      1000,
    );
    return () => {
      clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    const loadTracks = async () => {
      const tracks = [
        { name: "Bass", file: require("./assets/electricbass.wav") },
        { name: "Bongo", file: require("./assets/bongo.wav") },
        { name: "Drums", file: require("./assets/drums.wav") },
        { name: "Guitar", file: require("./assets/guitar.wav") },
      ];

      const loadedTracks = await Promise.all(
        tracks.map(async (track) => ({
          name: track.name,
          trackId: addTrack(track.file),
        })),
      );

      setSoundTracks(loadedTracks);
    };

    loadTracks();
  }, []);

  const handleSpeedChange = useCallback((value: number) => {
    setPlaybackSpeedState(value);

    // Clear any existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Only update playback speed when user stops sliding for 100ms
    timeoutRef.current = setTimeout(() => {
      setPlaybackSpeed(value);
    }, 100);
  }, []);

  const handleVolumeChange = useCallback((trackId: number, value: number) => {
    setVolumes((prev) => {
      const newVolumes = [...prev];
      newVolumes[trackId - 1] = value;
      return newVolumes;
    });
    setVolume(trackId, value);
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <Button title="Play" onPress={() => play()} />
        <Button title="Pause" onPress={() => pause()} />
        <Button title="Stop" onPress={() => stop()} />
        <Button title="Reset" onPress={() => reset()} />
        <Text>Current position {currentPos}</Text>
        <View style={styles.group}>
          <Text>Playback Speed: {playbackSpeed.toFixed(2)}x</Text>
          <Slider
            style={{ width: "100%", height: 40 }}
            minimumValue={0.7}
            maximumValue={1.3}
            value={playbackSpeed}
            onValueChange={handleSpeedChange}
            step={0.1}
          />
        </View>

        {soundTracks.map((track, i) => (
          <View key={i} style={styles.group}>
            <Text>{track.name}</Text>
            <Slider
              style={{ width: "100%", height: 40 }}
              minimumValue={0}
              maximumValue={1}
              value={volumes[i]}
              onValueChange={(value) =>
                handleVolumeChange(track.trackId, value)
              }
              step={0.1}
            />
            <Text>Volume: {volumes[i].toFixed(1)}</Text>
            <View
              style={{ flexDirection: "row", justifyContent: "space-around" }}
            >
              <Button title="Mute" onPress={() => mute(track.trackId)} />
              <Button title="Unmute" onPress={() => unmute(track.trackId)} />
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
  view: {
    flex: 1,
    height: 200,
  },
};
