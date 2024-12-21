export type AudioSource =
  | string
  | number
  | null
  | {
      /**
       * A string representing the resource identifier for the audio,
       * which could be an HTTPS address, a local file path, or the name of a static audio file resource.
       */
      uri?: string;
      /**
       * The asset ID of a local audio asset, acquired with the `require` function.
       * This property is exclusive with the `uri` property. When both are present, the `assetId` will be ignored.
       */
      assetId?: number;
    };
