const fs = require('fs');

console.log('prepare version args:', process.argv.slice(2));

const version = process.argv[2];

try {
	const pubspecPath = './pubspec.yaml';
	const versionRE = /version: ([\d]+\.[\d]+.[\d]+\+[\d]+)/;

	let data = fs.readFileSync(pubspecPath, 'utf8');
	const vmatch = data.match(versionRE);
	const oldFullVersion = vmatch.at(1);
	const oldVersionCode = oldFullVersion.split('+').at(1);
	const oldVersionName = oldFullVersion.split('+').at(0);

	const newVersionName = version.match(/[\d]+\.[\d]+.[\d]+/).at(0);

	if (oldVersionName === newVersionName) {
		console.warn('new version is equal to old', newVersionName);
	}

	const newVersionFullName = `${newVersionName}+${+oldVersionCode + 1}`;
	console.log(`old version: ${oldFullVersion}`);
	console.log(`updated version: ${newVersionFullName}`);

	data = data.replace(
		/version: [\d]+\.[\d]+.[\d]+\+[\d]+/,
		`version: ${newVersionFullName}`
	);

	fs.writeFileSync(pubspecPath, data, 'utf8');
} catch (err) {
	throw Error(`version update failed with error: ${err}`);
}