import fs from 'fs'; // Import the core fs module for streams
import { promises as fsPromises } from 'fs'; // Import promises API separately
import path from 'path';
import minimatch from 'minimatch';

// --- Configuration ---
const outputFile = 'project_context.txt';
const rootDir = '.'; // Start from the current directory

// Directories to completely ignore (if any part of the path matches)
const excludeDirs = new Set([
    'node_modules',
    '.git',
    '.next',
    'dist',
    'build',
    'out',
    'coverage',
    '.vscode',
    '.idea',
    '.swc',
    'migrations', // Example: Assuming it's nested under prisma/
    'uploads',    // Example: Assuming it's nested under public/
    'generated',  // Example: Assuming it's nested under src/
]);

// Specific file patterns to exclude (using minimatch glob patterns)
const excludeFilePatterns = [
    '.env*',                // Matches .env, .env.local, .env.production etc.
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml',
    '*.log',
    'npm-debug.log*',       // Example specific log files
    'yarn-debug.log*',
    'yarn-error.log*',
    'generate-context.js',  // Exclude this script itself
    outputFile,             // Exclude the output file itself
    'dev.db',               // Example: Exclude local db file
];

// File extensions to exclude
const excludeExtensions = new Set([
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.svg', // Images
    '.woff', '.woff2', '.ttf', '.eot',                      // Fonts
    '.pdf', '.zip', '.gz', '.tar', '.rar',                  // Archives/Documents
    '.exe', '.dll', '.so', '.dylib',                        // Binaries
    '.db', '.sqlite', '.sqlite3',                           // Databases
    '.DS_Store', 'Thumbs.db',                               // OS specific
    '.mp4', '.mov', '.avi', '.webm',                        // Videos
    '.mp3', '.wav', '.ogg',  '.md', '.txt',                              // Audio
]);

// Maximum file size in bytes (e.g., 1MB) to prevent reading huge files
const MAX_FILE_SIZE_BYTES = 1 * 1024 * 1024;

// --- End Configuration ---

let processedCount = 0;
let excludedCount = 0;
let outputStream;

/**
 * Checks if a given path should be excluded based on configuration.
 * @param {string} relativePath - Path relative to the root directory.
 * @param {fs.Dirent} dirent - The directory entry object from fsPromises.readdir.
 * @returns {{excluded: boolean, reason: string | null}} - Whether the path is excluded and why.
 */
function isExcluded(relativePath, dirent) {
    const pathParts = relativePath.split(path.sep);
    for (const part of pathParts) {
        if (excludeDirs.has(part)) {
            return { excluded: true, reason: `Directory (${part})` };
        }
    }

    if (dirent.isFile()) {
        const fileName = path.basename(relativePath);
        for (const pattern of excludeFilePatterns) {
            if (minimatch(fileName, pattern, { dot: true })) {
                return { excluded: true, reason: `File Pattern (${pattern})` };
            }
        }
        const ext = path.extname(fileName).toLowerCase();
        if (ext && excludeExtensions.has(ext)) {
            return { excluded: true, reason: `Extension (${ext})` };
        }
    }
    return { excluded: false, reason: null };
}

/**
 * Recursively walks directories and processes files.
 * @param {string} currentDir - The directory to process.
 * @param {string} rootDirAbs - The absolute path of the root directory for relative path calculation.
 */
async function processDirectory(currentDir, rootDirAbs) {
    let entries;
    try {
        // Use fsPromises for readdir
        entries = await fsPromises.readdir(currentDir, { withFileTypes: true });
    } catch (err) {
        console.warn(`[Warning] Could not read directory: ${currentDir} (${err.code || err.message})`);
        return;
    }

    entries.sort((a, b) => {
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
    });

    for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);
        // Ensure relativePath calculation handles the root case correctly
        const relativePath = path.relative(rootDirAbs, fullPath) || entry.name;


        const exclusionCheck = isExcluded(relativePath, entry);
        if (exclusionCheck.excluded) {
            excludedCount++;
            continue;
        }

        if (entry.isDirectory()) {
            await processDirectory(fullPath, rootDirAbs);
        } else if (entry.isFile()) {
            await processFile(fullPath, relativePath);
        }
    }
}

/**
 * Reads a file and appends its content to the output stream.
 * @param {string} filePath - Absolute path to the file.
 * @param {string} relativePath - Path relative to the root directory.
 */
async function processFile(filePath, relativePath) {
    let fileStats;
    try {
        // Use fsPromises for stat
        fileStats = await fsPromises.stat(filePath);
    } catch (err) {
        console.warn(`[Warning] Could not stat file: ${relativePath} (${err.code || err.message})`);
        excludedCount++;
        return;
    }

    if (fileStats.size > MAX_FILE_SIZE_BYTES) {
        console.log(`Skipping (File too large: ${Math.round(fileStats.size / 1024)} KB): ${relativePath}`);
        excludedCount++;
        await appendToOutput(`--- START FILE: ${relativePath} ---\n`);
        await appendToOutput(`[CONTENT SKIPPED: File size (${Math.round(fileStats.size / 1024)} KB) exceeds limit of ${Math.round(MAX_FILE_SIZE_BYTES / 1024)} KB]\n`);
        await appendToOutput(`--- END FILE: ${relativePath} ---\n\n`);
        return;
    }

    if (fileStats.size === 0) {
        console.log(`Processing (Empty): ${relativePath}`);
        processedCount++;
        await appendToOutput(`--- START FILE: ${relativePath} ---\n`);
        await appendToOutput(`[EMPTY FILE]\n`);
        await appendToOutput(`--- END FILE: ${relativePath} ---\n\n`);
        return;
    }

    console.log(`Processing: ${relativePath}`);
    let content = '';
    try {
        // Use fsPromises for readFile
        content = await fsPromises.readFile(filePath, 'utf8');
    } catch (err) {
        console.warn(`[Warning] Failed to read file as UTF-8: ${relativePath} (${err.code || err.message}). Appending error message.`);
        content = `[ERROR: Could not read file content - ${err.code || err.message}]`;
    }

    processedCount++;
    await appendToOutput(`--- START FILE: ${relativePath} ---\n`);
    await appendToOutput(content + '\n');
    await appendToOutput(`--- END FILE: ${relativePath} ---\n\n`);
}

/**
 * Appends data to the output file stream.
 * @param {string} data - The string data to append.
 */
async function appendToOutput(data) {
    if (!outputStream) {
        throw new Error("Output stream is not initialized.");
    }
    try {
        if (!outputStream.write(data)) {
            await new Promise(resolve => outputStream.once('drain', resolve));
        }
    } catch (err) {
        console.error(`[Error] Failed to write to output file: ${err.message}`);
        process.exit(1);
    }
}

/**
 * Main execution function.
 */
async function main() {
    console.log("--- Starting Context Script ---");
    const rootDirAbs = path.resolve(rootDir);
    const outputFilePath = path.resolve(outputFile);
    console.log(`Root directory: ${rootDirAbs}`);
    console.log(`Output file: ${outputFilePath}`);

    try {
        // Use the core 'fs' for createWriteStream
        outputStream = fs.createWriteStream(outputFilePath, { encoding: 'utf8' });

        await appendToOutput(`--- Project Context for ${path.basename(rootDirAbs)} ---\n`);
        await appendToOutput(`--- Generated on: ${new Date().toISOString()} ---\n`);
        await appendToOutput(`--- Root Directory: ${rootDirAbs} ---\n\n`);

        console.log("Searching for files and processing...");
        await processDirectory(rootDirAbs, rootDirAbs);

        await new Promise((resolve) => outputStream.end(resolve));

        console.log("--- Script Finished ---");
        console.log(`Processed ${processedCount} files.`);
        console.log(`Excluded ${excludedCount} files/directories.`);
        console.log(`Output saved to: ${outputFilePath}`);

    } catch (err) {
        console.error(`[Fatal Error] An error occurred: ${err.message}`);
        console.error(err.stack);
        if (outputStream && !outputStream.destroyed) {
            outputStream.end();
        }
        process.exit(1);
    }
}

// --- Run the script ---
main();