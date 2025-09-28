// A lightweight local list of common phrasal verbs with Turkish meanings.
// Used as an offline cache for quick lookups on tap in the reader.

class PhrasalVerbEntry {
  final String base; // e.g., "look up"
  final List<String> forms; // surface variants to match (lowercased)
  final String meaningTr;
  final bool separable; // e.g., pick it up

  const PhrasalVerbEntry({
    required this.base,
    required this.forms,
    required this.meaningTr,
    this.separable = false,
  });
}

// Note: All forms are lowercased. Matching should lowercase input before compare.
const List<PhrasalVerbEntry> kPhrasalVerbsTr = [
  PhrasalVerbEntry(
    base: 'look up',
    forms: ['look up', 'looked up', 'looking up', 'looks up'],
    meaningTr: 'bilgi aramak, sözlükte bakmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'look after',
    forms: ['look after', 'looked after', 'looking after', 'looks after'],
    meaningTr: 'bakmak, ilgilenmek',
  ),
  PhrasalVerbEntry(
    base: 'look for',
    forms: ['look for', 'looked for', 'looking for', 'looks for'],
    meaningTr: 'aramak',
  ),
  PhrasalVerbEntry(
    base: 'turn on',
    forms: ['turn on', 'turned on', 'turning on', 'turns on'],
    meaningTr: 'açmak (cihaz/ışık)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'turn off',
    forms: ['turn off', 'turned off', 'turning off', 'turns off'],
    meaningTr: 'kapamak (cihaz/ışık)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'pick up',
    forms: ['pick up', 'picked up', 'picking up', 'picks up'],
    meaningTr: 'almak, yerden kaldırmak; (dil) kapmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'put off',
    forms: ['put off', 'putting off', 'puts off'],
    meaningTr: 'ertelemek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'put on',
    forms: ['put on', 'putting on', 'puts on'],
    meaningTr: 'giymek; (müzik) açmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'put out',
    forms: ['put out', 'putting out', 'puts out'],
    meaningTr: 'söndürmek (yangın/sigara)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'bring up',
    forms: ['bring up', 'brought up', 'bringing up', 'brings up'],
    meaningTr: 'gündeme getirmek; büyütmek (çocuk)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'bring about',
    forms: ['bring about', 'brought about', 'bringing about', 'brings about'],
    meaningTr: 'sebep olmak, gerçekleştirmek',
  ),
  PhrasalVerbEntry(
    base: 'break down',
    forms: ['break down', 'broke down', 'broken down', 'breaking down', 'breaks down'],
    meaningTr: 'bozulmak; duygusal çöküş yaşamak',
  ),
  PhrasalVerbEntry(
    base: 'break up',
    forms: ['break up', 'broke up', 'broken up', 'breaking up', 'breaks up'],
    meaningTr: 'ayrılmak (ilişki); dağıtmak',
  ),
  PhrasalVerbEntry(
    base: 'carry on',
    forms: ['carry on', 'carried on', 'carrying on', 'carries on'],
    meaningTr: 'devam etmek',
  ),
  PhrasalVerbEntry(
    base: 'carry out',
    forms: ['carry out', 'carried out', 'carrying out', 'carries out'],
    meaningTr: 'yürütmek, gerçekleştirmek (görev/deney)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'come across',
    forms: ['come across', 'came across', 'come across', 'coming across', 'comes across'],
    meaningTr: 'tesadüfen karşılaşmak',
  ),
  PhrasalVerbEntry(
    base: 'come up with',
    forms: ['come up with', 'came up with', 'coming up with', 'comes up with'],
    meaningTr: 'fikir bulmak, çözüm üretmek',
  ),
  PhrasalVerbEntry(
    base: 'cut down on',
    forms: ['cut down on', 'cutting down on', 'cuts down on'],
    meaningTr: 'azaltmak (tüketim vb.)',
  ),
  PhrasalVerbEntry(
    base: 'cut off',
    forms: ['cut off', 'cutting off', 'cuts off'],
    meaningTr: 'kesmek, bağlantıyı koparmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'fall apart',
    forms: ['fall apart', 'fell apart', 'fallen apart', 'falling apart', 'falls apart'],
    meaningTr: 'parçalanmak; duygusal olarak dağılmak',
  ),
  PhrasalVerbEntry(
    base: 'fall out',
    forms: ['fall out', 'fell out', 'fallen out', 'falling out', 'falls out'],
    meaningTr: 'kavga etmek, aranın bozulması',
  ),
  PhrasalVerbEntry(
    base: 'find out',
    forms: ['find out', 'found out', 'finding out', 'finds out'],
    meaningTr: 'öğrenmek, keşfetmek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'get along',
    forms: ['get along', 'got along', 'getting along', 'gets along'],
    meaningTr: 'geçinmek, iyi anlaşmak',
  ),
  PhrasalVerbEntry(
    base: 'get over',
    forms: ['get over', 'got over', 'getting over', 'gets over'],
    meaningTr: 'üstesinden gelmek, atlatmak',
  ),
  PhrasalVerbEntry(
    base: 'give up',
    forms: ['give up', 'gave up', 'given up', 'giving up', 'gives up'],
    meaningTr: 'vazgeçmek, bırakmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'go on',
    forms: ['go on', 'went on', 'gone on', 'going on', 'goes on'],
    meaningTr: 'devam etmek; meydana gelmek',
  ),
  PhrasalVerbEntry(
    base: 'go over',
    forms: ['go over', 'went over', 'gone over', 'going over', 'goes over'],
    meaningTr: 'gözden geçirmek, üzerinden geçmek',
  ),
  PhrasalVerbEntry(
    base: 'hold on',
    forms: ['hold on', 'held on', 'holding on', 'holds on'],
    meaningTr: 'beklemek, hatta kalmak; sıkı tutmak',
  ),
  PhrasalVerbEntry(
    base: 'keep on',
    forms: ['keep on', 'kept on', 'keeping on', 'keeps on'],
    meaningTr: 'yapmaya devam etmek',
  ),
  PhrasalVerbEntry(
    base: 'look into',
    forms: ['look into', 'looked into', 'looking into', 'looks into'],
    meaningTr: 'incelemek, araştırmak',
  ),
  PhrasalVerbEntry(
    base: 'make up',
    forms: ['make up', 'made up', 'making up', 'makes up'],
    meaningTr: 'uydurmak; oluşturmak; barışmak; makyaj yapmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'pick out',
    forms: ['pick out', 'picked out', 'picking out', 'picks out'],
    meaningTr: 'seçmek, ayırt etmek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'point out',
    forms: ['point out', 'pointed out', 'pointing out', 'points out'],
    meaningTr: 'işaret etmek, belirtmek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'put up with',
    forms: ['put up with', 'putting up with', 'puts up with'],
    meaningTr: 'katlanmak, tahammül etmek',
  ),
  PhrasalVerbEntry(
    base: 'run into',
    forms: ['run into', 'ran into', 'running into', 'runs into'],
    meaningTr: 'tesadüfen karşılaşmak',
  ),
  PhrasalVerbEntry(
    base: 'run out of',
    forms: ['run out of', 'ran out of', 'running out of', 'runs out of'],
    meaningTr: 'tükenmek, bitmek',
  ),
  PhrasalVerbEntry(
    base: 'set up',
    forms: ['set up', 'setting up', 'sets up'],
    meaningTr: 'kurmak, düzenlemek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'show up',
    forms: ['show up', 'showed up', 'shown up', 'showing up', 'shows up'],
    meaningTr: 'ortaya çıkmak, gelmek',
  ),
  PhrasalVerbEntry(
    base: 'take off',
    forms: ['take off', 'took off', 'taken off', 'taking off', 'takes off'],
    meaningTr: 'havalanmak; çıkarmak (kıyafet)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'take on',
    forms: ['take on', 'took on', 'taken on', 'taking on', 'takes on'],
    meaningTr: 'üstlenmek; işe almak',
  ),
  PhrasalVerbEntry(
    base: 'take over',
    forms: ['take over', 'took over', 'taken over', 'taking over', 'takes over'],
    meaningTr: 'devralmak, kontrolü ele geçirmek',
  ),
  PhrasalVerbEntry(
    base: 'think over',
    forms: ['think over', 'thought over', 'thinking over', 'thinks over'],
    meaningTr: 'iyice düşünmek',
  ),
  PhrasalVerbEntry(
    base: 'throw away',
    forms: ['throw away', 'threw away', 'thrown away', 'throwing away', 'throws away'],
    meaningTr: 'çöpe atmak, elden çıkarmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'turn up',
    forms: ['turn up', 'turned up', 'turning up', 'turns up'],
    meaningTr: 'ortaya çıkmak; sesi açmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'turn down',
    forms: ['turn down', 'turned down', 'turning down', 'turns down'],
    meaningTr: 'reddetmek; sesi kısmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'work out',
    forms: ['work out', 'worked out', 'working out', 'works out'],
    meaningTr: 'çözmek; egzersiz yapmak; işe yaramak',
  ),
  PhrasalVerbEntry(
    base: 'figure out',
    forms: ['figure out', 'figured out', 'figuring out', 'figures out'],
    meaningTr: 'anlamak, çözmek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'bring back',
    forms: ['bring back', 'brought back', 'bringing back', 'brings back'],
    meaningTr: 'geri getirmek; hatırlatmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'call off',
    forms: ['call off', 'called off', 'calling off', 'calls off'],
    meaningTr: 'iptal etmek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'check out',
    forms: ['check out', 'checked out', 'checking out', 'checks out'],
    meaningTr: 'göz atmak; çıkış yapmak (otel)',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'come up',
    forms: ['come up', 'came up', 'coming up', 'comes up'],
    meaningTr: 'gündeme gelmek; ortaya çıkmak',
  ),
  PhrasalVerbEntry(
    base: 'drop off',
    forms: ['drop off', 'dropped off', 'dropping off', 'drops off'],
    meaningTr: 'bırakmak (arabayla); azalmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'end up',
    forms: ['end up', 'ended up', 'ending up', 'ends up'],
    meaningTr: 'sonuçlanmak, kendini ... durumda bulmak',
  ),
  PhrasalVerbEntry(
    base: 'fill out',
    forms: ['fill out', 'filled out', 'filling out', 'fills out'],
    meaningTr: 'form doldurmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'get back',
    forms: ['get back', 'got back', 'getting back', 'gets back'],
    meaningTr: 'geri dönmek; geri almak',
  ),
  PhrasalVerbEntry(
    base: 'give in',
    forms: ['give in', 'gave in', 'given in', 'giving in', 'gives in'],
    meaningTr: 'pes etmek, boyun eğmek',
  ),
  PhrasalVerbEntry(
    base: 'hang out',
    forms: ['hang out', 'hung out', 'hanging out', 'hangs out'],
    meaningTr: 'takılmak, vakit geçirmek',
  ),
  PhrasalVerbEntry(
    base: 'hang up',
    forms: ['hang up', 'hung up', 'hanging up', 'hangs up'],
    meaningTr: 'telefonu kapatmak; asmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'look forward to',
    forms: ['look forward to', 'looking forward to', 'looks forward to'],
    meaningTr: 'dört gözle beklemek',
  ),
  PhrasalVerbEntry(
    base: 'pay off',
    forms: ['pay off', 'paid off', 'paying off', 'pays off'],
    meaningTr: 'karşılığını vermek; borcu kapatmak',
  ),
  PhrasalVerbEntry(
    base: 'set off',
    forms: ['set off', 'setting off', 'sets off'],
    meaningTr: 'yola çıkmak; tetiklemek (alarm)',
  ),
  PhrasalVerbEntry(
    base: 'show off',
    forms: ['show off', 'showed off', 'shown off', 'showing off', 'shows off'],
    meaningTr: 'hava atmak, gösteriş yapmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'sort out',
    forms: ['sort out', 'sorted out', 'sorting out', 'sorts out'],
    meaningTr: 'çözmek, düzenlemek',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'wake up',
    forms: ['wake up', 'woke up', 'woken up', 'waking up', 'wakes up'],
    meaningTr: 'uyanmak; uyandırmak',
    separable: true,
  ),
  PhrasalVerbEntry(
    base: 'work on',
    forms: ['work on', 'worked on', 'working on', 'works on'],
    meaningTr: 'üzerinde çalışmak',
  ),
];


