import haxe.xml.Access;
import sys.io.File;

using StringTools;


class Main {
	static var xmlFile: Xml;
	static var xml: Access;
	static var path: Null<String>;

	static function main() {
		readXML();

		var style: String = xml.node.defs.node.style.innerData;
		var classes = searchStyleClasses(style);
		for (key => value in classes) {
			classes.set(key, parseStyleClass(style, key));
		}

		for (clKey => cls in classes) {
			for (rule => value in cls) {
				for (path in xmlFile.elementsNamed('path')) {
					var classAttr = path.get('class');
					if (classAttr == null || '.$classAttr' != clKey) continue;

					path.set(rule, value);
				}
			}
		}

		xmlFile.removeChild(xmlFile.elementsNamed('defs').next());
		xmlFile.removeChild(xmlFile.elementsNamed('metadata').next());

		File.saveContent('${path}_normalized.svg', xmlFile.toString());
	}

	static function readXML() {
		var args = Sys.args();
		path = args.length > 0 ? args[0] : null;

		if (path == null) {
			trace('[Must specify a file path.]');
			Sys.exit(0);
		}

		var file = File.getContent(path);
		xmlFile = Xml.parse(file).firstElement();
		xml = new Access(xmlFile);
	}

	static function parseStyleClass(style: String, name: String): Map<String, String> {
		final CLASS = 'CLASS';
		var regex = new EReg('(\\$name)(?=[,\\s\\{])', 'gi');
		style = regex.replace(style, CLASS);
		var idx = style.indexOf(CLASS);
		var map = new Map<String, String>();

		while (idx > -1) {
			var opBracketIdx = style.indexOf('{', idx);
			var clBracketIdx = style.indexOf('}', idx);
			var rules = style.substring(opBracketIdx + 1, clBracketIdx);
			rules = rules.replace(': ', ' ').replace(';', '');
			var rulesArray = rules.split('\n');

			for (i in 0...rulesArray.length) rulesArray[i] = rulesArray[i].trim();

			while (rulesArray.remove('')) {}

			for (rule in rulesArray) {
				var r = rule.trim().split(' ');

				map.set(r[0], r[1]);
			}

			idx = style.indexOf(CLASS, clBracketIdx);
		}

		return map;
	}

	static function searchStyleClasses(style: String): Map<String, Map<String, String>> {
		function getMatches(ereg:EReg, input:String, index:Int = 0):Array<String> {
			var matches = [];

			while (ereg.match(input)) {
				matches.push(ereg.matched(index));
				input = ereg.matchedRight();
			}

			return matches;
		}

		var classes = new Map<String, Map<String, String>>();

		var regex = ~/(\.cls-\d+)(?=[,\s\{])/gi;

		var matches = getMatches(regex, style);

		for (match in matches) {
			if (classes.exists(match)) continue;

			var rules = new Map<String, String>();
			classes.set(match, rules);
		}

		return classes;
	}
}
