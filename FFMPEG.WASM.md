### FFMPEG.WASM

##### ffmpeg.wasm is a pure WebAssembly / JavaScript port of FFmpeg. It enables video & audio record, convert and stream right inside browsers.

[GET STARTED](https://ffmpegwasm.netlify.app/#installation)

[DOCUMENTATION](https://github.com/ffmpegwasm/ffmpeg.wasm/blob/master/docs/api.md)

#### External Libraries

###### ffmpeg.wasm is built with common external libraries, and more of libraries to be added! (You can request them [HERE](https://github.com/ffmpegwasm/ffmpeg.wasm/issues/61))

#### Installation

###### Install ffmpeg.wasm:

```
# Use npm
$ npm install @ffmpeg/ffmpeg @ffmpeg/core
# Use yarn
$ yarn add @ffmpeg/ffmpeg @ffmpeg/core
```

#### Usage

###### With few lines of code you can use ffmpeg.wasm

###### Browser

```
<body>
  <video id="player" controls></video>
  <input type="file" id="uploader">
  <script src="ffmpeg.min.js"></script>
  <script>
    const { createFFmpeg, fetchFile } = FFmpeg;
    const ffmpeg = createFFmpeg({ log: true });
    const transcode = async ({ target: { files } }) => {
      const { name } = files[0];
      await ffmpeg.load();
      ffmpeg.FS('writeFile', name, await fetchFile(files[0]));
      await ffmpeg.run('-i', name,  'output.mp4');
      const data = ffmpeg.FS('readFile', 'output.mp4');
      const video = document.getElementById('player');
      video.src = URL.createObjectURL(new Blob([data.buffer], { type: 'video/mp4' }));
    }
    document
      .getElementById('uploader').addEventListener('change', transcode);
  </script>
</body>
```

###### Node.JS

```
const fs = require('fs');const { createFFmpeg, fetchFile } = require('@ffmpeg/ffmpeg');
const ffmpeg = createFFmpeg({ log: true });
(async () => {  await ffmpeg.load();  ffmpeg.FS('writeFile', 'test.avi', await fetchFile('./test.avi'));  await ffmpeg.run('-i', 'test.avi', 'test.mp4');  await fs.promises.writeFile('./test.mp4', ffmpeg.FS('readFile', 'test.mp4'));  process.exit(0);})();
```