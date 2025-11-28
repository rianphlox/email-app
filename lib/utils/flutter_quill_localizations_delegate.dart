import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A custom localizations delegate to resolve FlutterQuill localization requirements
class FlutterQuillLocalizationsDelegate extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const FlutterQuillLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) {
    return SynchronousFuture<FlutterQuillLocalizations>(
      FlutterQuillLocalizations(locale),
    );
  }

  @override
  bool shouldReload(FlutterQuillLocalizationsDelegate old) => false;

  @override
  Type get type => FlutterQuillLocalizations;
}

/// Custom FlutterQuill localizations class
class FlutterQuillLocalizations {
  const FlutterQuillLocalizations(this.locale);

  final Locale locale;

  static FlutterQuillLocalizations of(BuildContext context) {
    return Localizations.of<FlutterQuillLocalizations>(
      context,
      FlutterQuillLocalizations,
    ) ?? const FlutterQuillLocalizations(Locale('en', 'US'));
  }

  static const LocalizationsDelegate<FlutterQuillLocalizations> delegate =
      FlutterQuillLocalizationsDelegate();

  // Provide basic text strings for FlutterQuill
  String get bold => 'Bold';
  String get italic => 'Italic';
  String get underline => 'Underline';
  String get strikeThrough => 'Strike Through';
  String get inlineCode => 'Inline Code';
  String get fontSize => 'Font Size';
  String get fontFamily => 'Font Family';
  String get color => 'Color';
  String get backgroundColor => 'Background Color';
  String get clearFormat => 'Clear Format';
  String get alignLeft => 'Align Left';
  String get alignCenter => 'Align Center';
  String get alignRight => 'Align Right';
  String get alignJustify => 'Justify';
  String get justifyWinWidth => 'Justify';
  String get textDirection => 'Text Direction';
  String get headerStyle => 'Header Style';
  String get normalText => 'Normal Text';
  String get heading1 => 'Heading 1';
  String get heading2 => 'Heading 2';
  String get heading3 => 'Heading 3';
  String get heading4 => 'Heading 4';
  String get heading5 => 'Heading 5';
  String get heading6 => 'Heading 6';
  String get numberedList => 'Numbered List';
  String get bulletList => 'Bullet List';
  String get checkedList => 'Checked List';
  String get codeBlock => 'Code Block';
  String get quote => 'Quote';
  String get increaseIndent => 'Increase Indent';
  String get decreaseIndent => 'Decrease Indent';
  String get insertURL => 'Insert URL';
  String get visitLink => 'Visit Link';
  String get enterLink => 'Enter Link';
  String get enterMedia => 'Enter Media';
  String get edit => 'Edit';
  String get apply => 'Apply';
  String get fontColorTooltip => 'Font Color';
  String get backgroundColorTooltip => 'Background Color';
  String get insertImage => 'Insert Image';
  String get insertVideo => 'Insert Video';
  String get insertIconTooltip => 'Insert Icon';
  String get insertTableTooltip => 'Insert Table';
  String get insertHorizontalRuleTooltip => 'Insert Horizontal Rule';
  String get pasteLink => 'Paste Link';
  String get ok => 'Ok';
  String get selectColor => 'Select Color';
  String get gallery => 'Gallery';
  String get link => 'Link';
  String get open => 'Open';
  String get copy => 'Copy';
  String get remove => 'Remove';
  String get save => 'Save';
  String get zoom => 'Zoom';
  String get saved => 'Saved';
  String get text => 'Text';
  String get resize => 'Resize';
  String get width => 'Width';
  String get height => 'Height';
  String get size => 'Size';
  String get small => 'Small';
  String get large => 'Large';
  String get huge => 'Huge';
  String get clear => 'Clear';
  String get font => 'Font';
  String get search => 'Search';
  String get camera => 'Camera';
  String get video => 'Video';
  String get undo => 'Undo';
  String get redo => 'Redo';
  String get fontFamilyDisplayName => 'Font Family';
  String get fontSizeDisplayName => 'Font Size';
  String get linkAddTooltip => 'Add Link';
  String get linkEditTooltip => 'Edit Link';
  String get linkRemoveTooltip => 'Remove Link';
  String get clipboard => 'Clipboard';
  String get cut => 'Cut';
  String get paste => 'Paste';
  String get selectAll => 'Select All';
}