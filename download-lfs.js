import https from 'https';
import fs from 'fs';
import path from 'path';

const files = [
  {
    url: 'https://media.githubusercontent.com/media/antomgarre/fabled-kingdoms/main/web/index.pck',
    dest: 'web/index.pck'
  },
  {
    url: 'https://media.githubusercontent.com/media/antomgarre/fabled-kingdoms/main/web/index.wasm',
    dest: 'web/index.wasm'
  }
];

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    console.log(`Downloading ${url} to ${dest}...`);
    const file = fs.createWriteStream(dest);
    
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        console.log(`Redirected to ${response.headers.location}`);
        return downloadFile(response.headers.location, dest).then(resolve).catch(reject);
      }
      
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to get '${url}' (${response.statusCode})`));
        return;
      }
      
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log(`Successfully downloaded ${dest}`);
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function main() {
  try {
    for (const file of files) {
      await downloadFile(file.url, file.dest);
    }
    console.log('All LFS files downloaded successfully.');
  } catch (err) {
    console.error('Error downloading LFS files:', err);
    process.exit(1);
  }
}

main();
