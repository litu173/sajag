import 'models.dart';

/// Why a post can't be published as written.
enum PolicyIssue { political, person, celebrity, personalGain, contact }

PolicyIssue? policyIssueFromWire(String? s) => switch (s) {
  'political' => PolicyIssue.political,
  'person' => PolicyIssue.person,
  'celebrity' => PolicyIssue.celebrity,
  'personal_gain' => PolicyIssue.personalGain,
  'contact' => PolicyIssue.contact,
  _ => null,
};

/// The same screening the server applies (shared/moderation.json → public.moderation_terms), run
/// before posting so people can fix their text instead of having the post held.
class ContentPolicy {
  ContentPolicy(List<({String kind, String pattern})> terms)
    : _rules = [
        for (final t in terms)
          if (policyIssueFromWire(t.kind) case final issue?)
            (issue: issue, re: RegExp(t.pattern, caseSensitive: false, unicode: true)),
      ];

  factory ContentPolicy.fromJson(Json j) => ContentPolicy([
    for (final t in (j['terms'] as List<dynamic>).cast<Json>())
      (kind: t['kind'] as String, pattern: t['pattern'] as String),
  ]);

  final List<({PolicyIssue issue, RegExp re})> _rules;

  /// The most serious issue the text trips, or null when it reads like a hazard report.
  PolicyIssue? check(String text) {
    PolicyIssue? found;
    for (final r in _rules) {
      if (r.re.hasMatch(text) && (found == null || r.issue.index < found.index)) found = r.issue;
    }
    return found;
  }
}
