import '../models/email_message.dart';

/// A service that detects spam and phishing emails using various heuristics
class SpamDetectionService {
  // Spam keywords with weighted scores
  static const Map<String, double> _spamKeywords = {
    // High risk (3.0 points)
    'viagra': 3.0,
    'click here now': 3.0,
    'limited time offer': 3.0,
    'congratulations you have won': 3.0,
    'nigerian prince': 3.0,
    'inheritance': 3.0,
    'lottery winner': 3.0,
    'million dollars': 3.0,
    'wire transfer': 3.0,
    'urgent response': 3.0,
    'confirm your account': 3.0,
    'verify your identity': 3.0,
    'suspended account': 3.0,
    'immediate action required': 3.0,

    // Medium risk (2.0 points)
    'free money': 2.0,
    'get rich quick': 2.0,
    'work from home': 2.0,
    'make money fast': 2.0,
    'no risk': 2.0,
    'guaranteed': 2.0,
    'act now': 2.0,
    'limited time': 2.0,
    'expires today': 2.0,
    'final notice': 2.0,
    'last chance': 2.0,
    'click here': 2.0,
    'download now': 2.0,
    'bonus': 2.0,

    // Low risk (1.0 points)
    'free': 1.0,
    'offer': 1.0,
    'discount': 1.0,
    'sale': 1.0,
    'promotion': 1.0,
    'deal': 1.0,
    'save money': 1.0,
    'special offer': 1.0,
    'limited offer': 1.0,
    'subscribe': 1.0,
    'unsubscribe': 1.0,
  };

  // Phishing keywords with weighted scores
  static const Map<String, double> _phishingKeywords = {
    // High risk (4.0 points)
    'update your password': 4.0,
    'verify your account': 4.0,
    'confirm your identity': 4.0,
    'security alert': 4.0,
    'suspicious activity': 4.0,
    'unauthorized access': 4.0,
    'account locked': 4.0,
    'account suspended': 4.0,
    'click to verify': 4.0,
    'immediate verification': 4.0,
    'temporary suspension': 4.0,

    // Medium risk (2.5 points)
    'login credentials': 2.5,
    'update payment': 2.5,
    'billing information': 2.5,
    'credit card': 2.5,
    'payment failed': 2.5,
    'update profile': 2.5,
    'security breach': 2.5,
    'verify now': 2.5,
    'confirm email': 2.5,

    // Low risk (1.5 points)
    'security': 1.5,
    'verification': 1.5,
    'account': 1.5,
    'password': 1.5,
    'login': 1.5,
    'signin': 1.5,
    'update': 1.5,
  };

  // Trusted domains that are less likely to be spam/phishing
  static const Set<String> _trustedDomains = {
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'apple.com',
    'microsoft.com',
    'google.com',
    'amazon.com',
    'facebook.com',
    'twitter.com',
    'linkedin.com',
    'github.com',
    'stackoverflow.com',
    'reddit.com',
    'youtube.com',
    'netflix.com',
    'spotify.com',
  };

  // Suspicious TLDs (top-level domains)
  static const Set<String> _suspiciousTlds = {
    '.tk',
    '.ml',
    '.ga',
    '.cf',
    '.click',
    '.download',
    '.science',
    '.work',
    '.party',
    '.stream',
    '.top',
    '.win',
    '.bid',
    '.trade',
    '.date',
    '.racing',
    '.review',
  };

  /// Analyzes an email and returns a spam/phishing detection result
  static SpamDetectionResult analyzeEmail(EmailMessage email) {
    double spamScore = 0.0;
    double phishingScore = 0.0;
    List<String> detectedPatterns = [];

    // Analyze sender domain
    final senderAnalysis = _analyzeSender(email.from);
    spamScore += senderAnalysis.spamScore;
    phishingScore += senderAnalysis.phishingScore;
    detectedPatterns.addAll(senderAnalysis.patterns);

    // Analyze subject line
    final subjectAnalysis = _analyzeText(email.subject, isSubject: true);
    spamScore += subjectAnalysis.spamScore;
    phishingScore += subjectAnalysis.phishingScore;
    detectedPatterns.addAll(subjectAnalysis.patterns);

    // Analyze body content
    final bodyText = email.htmlBody ?? email.textBody;
    final bodyAnalysis = _analyzeText(bodyText);
    spamScore += bodyAnalysis.spamScore;
    phishingScore += bodyAnalysis.phishingScore;
    detectedPatterns.addAll(bodyAnalysis.patterns);

    // Analyze URLs in content
    final urlAnalysis = _analyzeUrls(bodyText);
    spamScore += urlAnalysis.spamScore;
    phishingScore += urlAnalysis.phishingScore;
    detectedPatterns.addAll(urlAnalysis.patterns);

    // Check for urgency indicators
    final urgencyAnalysis = _analyzeUrgency('${email.subject} $bodyText');
    spamScore += urgencyAnalysis.spamScore;
    phishingScore += urgencyAnalysis.phishingScore;
    detectedPatterns.addAll(urgencyAnalysis.patterns);

    // Determine final classification
    SpamRiskLevel spamRisk;
    PhishingRiskLevel phishingRisk;

    if (spamScore >= 5.0) {
      spamRisk = SpamRiskLevel.high;
    } else if (spamScore >= 3.0) {
      spamRisk = SpamRiskLevel.medium;
    } else if (spamScore >= 1.5) {
      spamRisk = SpamRiskLevel.low;
    } else {
      spamRisk = SpamRiskLevel.none;
    }

    if (phishingScore >= 6.0) {
      phishingRisk = PhishingRiskLevel.high;
    } else if (phishingScore >= 4.0) {
      phishingRisk = PhishingRiskLevel.medium;
    } else if (phishingScore >= 2.0) {
      phishingRisk = PhishingRiskLevel.low;
    } else {
      phishingRisk = PhishingRiskLevel.none;
    }

    return SpamDetectionResult(
      spamRisk: spamRisk,
      phishingRisk: phishingRisk,
      spamScore: spamScore,
      phishingScore: phishingScore,
      detectedPatterns: detectedPatterns.toSet().toList(),
      confidence: _calculateConfidence(spamScore, phishingScore),
    );
  }

  static _SenderAnalysis _analyzeSender(String fromField) {
    double spamScore = 0.0;
    double phishingScore = 0.0;
    List<String> patterns = [];

    final emailMatch = RegExp(r'<(.+?)>').firstMatch(fromField);
    final email = emailMatch?.group(1) ?? fromField;

    if (email.contains('@')) {
      final parts = email.split('@');
      if (parts.length == 2) {
        final domain = parts[1].toLowerCase();

        // Check if domain is trusted
        if (_trustedDomains.contains(domain)) {
          // Reduce scores for trusted domains
          spamScore -= 1.0;
          phishingScore -= 1.0;
        }

        // Check for suspicious TLDs
        for (final tld in _suspiciousTlds) {
          if (domain.endsWith(tld)) {
            spamScore += 2.0;
            phishingScore += 2.0;
            patterns.add('Suspicious domain: $domain');
            break;
          }
        }

        // Check for domain spoofing patterns
        if (_isDomainSpoofing(domain)) {
          phishingScore += 3.0;
          patterns.add('Potential domain spoofing: $domain');
        }

        // Check for random/suspicious domain patterns
        if (_isSuspiciousDomain(domain)) {
          spamScore += 1.5;
          patterns.add('Suspicious domain pattern: $domain');
        }
      }
    }

    return _SenderAnalysis(spamScore, phishingScore, patterns);
  }

  static _TextAnalysis _analyzeText(String text, {bool isSubject = false}) {
    double spamScore = 0.0;
    double phishingScore = 0.0;
    List<String> patterns = [];

    final lowerText = text.toLowerCase();

    // Check spam keywords
    _spamKeywords.forEach((keyword, score) {
      if (lowerText.contains(keyword)) {
        final adjustedScore = isSubject ? score * 1.5 : score;
        spamScore += adjustedScore;
        patterns.add('Spam keyword: $keyword');
      }
    });

    // Check phishing keywords
    _phishingKeywords.forEach((keyword, score) {
      if (lowerText.contains(keyword)) {
        final adjustedScore = isSubject ? score * 1.5 : score;
        phishingScore += adjustedScore;
        patterns.add('Phishing keyword: $keyword');
      }
    });

    // Check for excessive capitalization
    final upperCaseCount = text.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
    final upperCaseRatio = upperCaseCount / text.length;
    if (upperCaseRatio > 0.5 && text.length > 10) {
      spamScore += 1.5;
      patterns.add('Excessive capitalization');
    }

    // Check for excessive punctuation
    final punctuationCount = text.split('').where((c) => '!?'.contains(c)).length;
    if (punctuationCount > 3) {
      spamScore += 1.0;
      patterns.add('Excessive punctuation');
    }

    return _TextAnalysis(spamScore, phishingScore, patterns);
  }

  static _UrlAnalysis _analyzeUrls(String text) {
    double spamScore = 0.0;
    double phishingScore = 0.0;
    List<String> patterns = [];

    final urlRegex = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
    final urls = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        final domain = uri.host.toLowerCase();

        // Check for URL shorteners (often used in spam/phishing)
        final shorteners = ['bit.ly', 'tinyurl.com', 'short.link', 't.co', 'ow.ly', 'goo.gl'];
        if (shorteners.any((s) => domain.contains(s))) {
          spamScore += 1.0;
          phishingScore += 1.5;
          patterns.add('URL shortener detected: $domain');
        }

        // Check for suspicious TLDs in URLs
        for (final tld in _suspiciousTlds) {
          if (domain.endsWith(tld)) {
            spamScore += 2.0;
            phishingScore += 2.0;
            patterns.add('Suspicious URL domain: $domain');
            break;
          }
        }

        // Check for domain spoofing in URLs
        if (_isDomainSpoofing(domain)) {
          phishingScore += 4.0;
          patterns.add('Potential URL spoofing: $domain');
        }

        // Check for excessive subdomains
        final subdomains = domain.split('.');
        if (subdomains.length > 4) {
          phishingScore += 1.5;
          patterns.add('Excessive subdomains: $domain');
        }

      } catch (e) {
        // Invalid URL format
        spamScore += 0.5;
        patterns.add('Invalid URL format detected');
      }
    }

    return _UrlAnalysis(spamScore, phishingScore, patterns);
  }

  static _UrgencyAnalysis _analyzeUrgency(String text) {
    double spamScore = 0.0;
    double phishingScore = 0.0;
    List<String> patterns = [];

    final urgencyPhrases = {
      'urgent': 2.0,
      'immediate': 2.0,
      'expires today': 2.5,
      'expires soon': 2.0,
      'act now': 2.5,
      'limited time': 2.0,
      'hurry': 1.5,
      'deadline': 1.5,
      'final notice': 3.0,
      'last chance': 2.5,
      'time sensitive': 2.0,
      'action required': 2.5,
    };

    final lowerText = text.toLowerCase();
    urgencyPhrases.forEach((phrase, score) {
      if (lowerText.contains(phrase)) {
        spamScore += score;
        phishingScore += score * 1.2; // Phishing often uses urgency
        patterns.add('Urgency indicator: $phrase');
      }
    });

    return _UrgencyAnalysis(spamScore, phishingScore, patterns);
  }

  static bool _isDomainSpoofing(String domain) {
    final commonTargets = {
      'paypal': ['payp4l', 'paypaI', 'paypal1', 'paypalI'],
      'amazon': ['arnazon', 'amazom', 'amaz0n'],
      'google': ['g00gle', 'googIe', 'goog1e'],
      'apple': ['appIe', 'appl3', 'app1e'],
      'microsoft': ['microsft', 'micr0soft', 'microsooft'],
      'facebook': ['faceb00k', 'facebok', 'faceboook'],
      'twitter': ['twiter', 'twitterr', 'tw1tter'],
      'instagram': ['instragram', 'instagr4m', 'instgram'],
    };

    for (final target in commonTargets.keys) {
      if (domain.contains(target)) {
        // Check if it's exactly the target or a spoofed version
        for (final spoofed in commonTargets[target]!) {
          if (domain.contains(spoofed)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool _isSuspiciousDomain(String domain) {
    // Check for domains with excessive hyphens
    if (domain.split('-').length > 3) {
      return true;
    }

    // Check for domains with numbers mixed with letters
    if (RegExp(r'[0-9]').hasMatch(domain) && RegExp(r'[a-z]').hasMatch(domain)) {
      final numbers = domain.split('').where((c) => RegExp(r'[0-9]').hasMatch(c)).length;
      final letters = domain.split('').where((c) => RegExp(r'[a-z]').hasMatch(c)).length;
      if (numbers / (numbers + letters) > 0.3) {
        return true;
      }
    }

    // Check for very long domains
    if (domain.length > 30) {
      return true;
    }

    return false;
  }

  static double _calculateConfidence(double spamScore, double phishingScore) {
    final maxScore = spamScore > phishingScore ? spamScore : phishingScore;

    if (maxScore >= 6.0) return 0.95;
    if (maxScore >= 4.0) return 0.85;
    if (maxScore >= 2.0) return 0.75;
    if (maxScore >= 1.0) return 0.65;
    return 0.5;
  }
}

// Helper classes for analysis results
class _SenderAnalysis {
  final double spamScore;
  final double phishingScore;
  final List<String> patterns;

  _SenderAnalysis(this.spamScore, this.phishingScore, this.patterns);
}

class _TextAnalysis {
  final double spamScore;
  final double phishingScore;
  final List<String> patterns;

  _TextAnalysis(this.spamScore, this.phishingScore, this.patterns);
}

class _UrlAnalysis {
  final double spamScore;
  final double phishingScore;
  final List<String> patterns;

  _UrlAnalysis(this.spamScore, this.phishingScore, this.patterns);
}

class _UrgencyAnalysis {
  final double spamScore;
  final double phishingScore;
  final List<String> patterns;

  _UrgencyAnalysis(this.spamScore, this.phishingScore, this.patterns);
}

/// Result of spam/phishing detection analysis
class SpamDetectionResult {
  final SpamRiskLevel spamRisk;
  final PhishingRiskLevel phishingRisk;
  final double spamScore;
  final double phishingScore;
  final List<String> detectedPatterns;
  final double confidence;

  SpamDetectionResult({
    required this.spamRisk,
    required this.phishingRisk,
    required this.spamScore,
    required this.phishingScore,
    required this.detectedPatterns,
    required this.confidence,
  });

  bool get isSpam => spamRisk != SpamRiskLevel.none;
  bool get isPhishing => phishingRisk != PhishingRiskLevel.none;
  bool get isSuspicious => isSpam || isPhishing;

  String get riskSummary {
    if (phishingRisk == PhishingRiskLevel.high) {
      return 'High phishing risk';
    } else if (spamRisk == SpamRiskLevel.high) {
      return 'High spam risk';
    } else if (phishingRisk == PhishingRiskLevel.medium) {
      return 'Medium phishing risk';
    } else if (spamRisk == SpamRiskLevel.medium) {
      return 'Medium spam risk';
    } else if (phishingRisk == PhishingRiskLevel.low || spamRisk == SpamRiskLevel.low) {
      return 'Low risk';
    } else {
      return 'Low risk';
    }
  }

  @override
  String toString() {
    return 'SpamDetectionResult(spam: $spamRisk, phishing: $phishingRisk, '
           'confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

enum SpamRiskLevel {
  none,
  low,
  medium,
  high,
}

enum PhishingRiskLevel {
  none,
  low,
  medium,
  high,
}