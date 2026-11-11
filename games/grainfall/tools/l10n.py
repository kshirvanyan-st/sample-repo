#!/usr/bin/env python3
"""Generates App/Resources/Localizable.xcstrings (Xcode String Catalog) for the PRD's launch
languages from:
  • the UI table below (keys exactly as SwiftUI extracts them: Int → %lld, String/Text → %@), and
  • tools/l10n/levels.json — translated level names, hints and chapter names.

Run after adding UI strings or levels:  python3 tools/l10n.py
A missing translation falls back to English at runtime, so a gap is never a crash.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["es", "fr", "de", "pt-BR", "ja", "ko", "zh-Hans"]

# key: [es, fr, de, pt-BR, ja, ko, zh-Hans]
UI = {
    "Play": ["Jugar", "Jouer", "Spielen", "Jogar", "プレイ", "플레이", "开始"],
    "Continue": ["Continuar", "Continuer", "Weiter", "Continuar", "つづける", "계속하기", "继续"],
    "Levels": ["Niveles", "Niveaux", "Level", "Fases", "レベル", "레벨", "关卡"],
    "Settings": ["Ajustes", "Réglages", "Einstellungen", "Ajustes", "設定", "설정", "设置"],
    "Dig. Pour. Solve.": ["Cava. Vierte. Resuelve.", "Creuse. Verse. Résous.", "Graben. Gießen. Lösen.",
                          "Cave. Despeje. Resolva.", "掘って、注いで、解く。", "파고, 붓고, 푼다.", "挖掘。倾倒。解谜。"],
    "%lld chapters free": ["%lld capítulos gratis", "%lld chapitres gratuits", "%lld Kapitel gratis",
                           "%lld capítulos grátis", "%lld章まで無料", "%lld개 챕터 무료", "%lld 个章节免费"],
    "Back": ["Atrás", "Retour", "Zurück", "Voltar", "戻る", "뒤로", "返回"],
    "%lld stars collected": ["%lld estrellas conseguidas", "%lld étoiles obtenues", "%lld Sterne gesammelt",
                             "%lld estrelas coletadas", "スター%lld個獲得", "별 %lld개 획득", "已获得 %lld 颗星"],
    "More chapters coming soon": ["Más capítulos muy pronto", "D'autres chapitres arrivent bientôt",
                                  "Weitere Kapitel folgen bald", "Mais capítulos em breve", "新しい章を準備中",
                                  "더 많은 챕터가 곧 찾아옵니다", "更多章节即将推出"],
    "Unlock": ["Desbloquear", "Débloquer", "Freischalten", "Desbloquear", "解除", "잠금 해제", "解锁"],
    "Level %@, %@, %lld stars": ["Nivel %1$@, %2$@, %3$lld estrellas", "Niveau %1$@, %2$@, %3$lld étoiles",
                                 "Level %1$@, %2$@, %3$lld Sterne", "Fase %1$@, %2$@, %3$lld estrelas",
                                 "レベル%1$@「%2$@」スター%3$lld個", "레벨 %1$@, %2$@, 별 %3$lld개",
                                 "关卡 %1$@，%2$@，%3$lld 颗星"],
    "Level %@, locked": ["Nivel %@, bloqueado", "Niveau %@, verrouillé", "Level %@, gesperrt", "Fase %@, bloqueada",
                         "レベル%@（ロック中）", "레벨 %@, 잠김", "关卡 %@，未解锁"],
    "%lld of 3 stars": ["%lld de 3 estrellas", "%lld étoiles sur 3", "%lld von 3 Sternen", "%lld de 3 estrelas",
                        "3つ中%lld個のスター", "별 3개 중 %lld개", "3 颗星中的 %lld 颗"],
    "Restart": ["Reiniciar", "Recommencer", "Neustart", "Reiniciar", "やり直す", "다시 시작", "重新开始"],
    "Pause": ["Pausa", "Pause", "Pause", "Pausar", "一時停止", "일시정지", "暂停"],
    "Paused": ["En pausa", "En pause", "Pausiert", "Pausado", "一時停止中", "일시정지됨", "已暂停"],
    "Resume": ["Reanudar", "Reprendre", "Fortsetzen", "Retomar", "再開", "계속", "继续"],
    "Dig budget": ["Excavación restante", "Réserve de creusage", "Grab-Vorrat", "Escavação restante",
                   "掘れる量", "남은 파기량", "可挖掘量"],
    "%lld percent left": ["Queda un %lld %%", "Il reste %lld %%", "Noch %lld %%", "Restam %lld%%",
                          "残り%lld%%", "%lld%% 남음", "剩余 %lld%%"],
    "Blast charges: %lld": ["Cargas explosivas: %lld", "Charges explosives : %lld", "Sprengladungen: %lld",
                            "Cargas explosivas: %lld", "爆破チャージ：%lld", "폭파 충전: %lld", "爆破次数：%lld"],
    "Armed. Tap the board to blast.": ["Preparada. Toca el tablero para explotar.",
                                       "Armée. Touchez le plateau pour faire exploser.",
                                       "Scharf. Tippe aufs Spielfeld, um zu sprengen.",
                                       "Armada. Toque no tabuleiro para explodir.",
                                       "準備完了。盤面をタップして爆破。", "준비 완료. 보드를 탭해 폭파하세요.",
                                       "已就绪。点按棋盘引爆。"],
    "Arms a blast for your next tap.": ["Prepara una explosión para tu próximo toque.",
                                        "Prépare une explosion pour votre prochain toucher.",
                                        "Macht eine Sprengung für dein nächstes Tippen bereit.",
                                        "Prepara uma explosão para o próximo toque.",
                                        "次のタップで爆破します。", "다음 탭에 폭파를 준비합니다.",
                                        "下次点按时引爆。"],
    "Show hint": ["Ver pista", "Afficher l'indice", "Tipp zeigen", "Mostrar dica", "ヒントを表示", "힌트 보기", "显示提示"],
    "Hide hint": ["Ocultar pista", "Masquer l'indice", "Tipp ausblenden", "Ocultar dica", "ヒントを隠す", "힌트 숨기기", "隐藏提示"],
    "Dismisses the hint": ["Cierra la pista", "Ferme l'indice", "Schließt den Tipp", "Fecha a dica",
                           "ヒントを閉じます", "힌트를 닫습니다", "关闭提示"],
    "Drag to dig a path for the sand": ["Arrastra para cavar un camino para la arena",
                                        "Glissez pour creuser un chemin au sable",
                                        "Ziehe, um dem Sand einen Weg zu graben",
                                        "Arraste para cavar um caminho para a areia",
                                        "ドラッグして砂の通り道を掘ろう", "드래그해서 모래가 지나갈 길을 파세요",
                                        "拖动手指，为沙子挖出通道"],
    "Stuck? Try again": ["¿Atascado? Inténtalo de nuevo", "Bloqué ? Réessayez", "Feststeckt? Nochmal versuchen",
                         "Travou? Tente de novo", "詰まった？もう一度", "막혔나요? 다시 해 보세요", "卡住了？再试一次"],
    "Poured!": ["¡Vertido!", "Versé !", "Eingegossen!", "Despejado!", "注ぎきった！", "완성!", "倒满啦！"],
    "Chapter %lld complete!": ["¡Capítulo %lld completado!", "Chapitre %lld terminé !", "Kapitel %lld geschafft!",
                               "Capítulo %lld concluído!", "第%lld章クリア！", "%lld장 완료!", "第 %lld 章完成！"],
    "Dug %lld cells": ["Has cavado %lld celdas", "%lld cases creusées", "%lld Felder gegraben",
                       "%lld células escavadas", "%lldマス掘った", "%lld칸 팠음", "挖了 %lld 格"],
    "New best": ["Nuevo récord", "Nouveau record", "Neuer Rekord", "Novo recorde", "自己ベスト", "최고 기록", "新纪录"],
    "Dig less for more stars": ["Cava menos para más estrellas", "Creusez moins pour plus d'étoiles",
                                "Weniger graben, mehr Sterne", "Cave menos para mais estrelas",
                                "掘る量を減らすとスターが増える", "덜 팔수록 별을 더 받아요", "挖得越少，星星越多"],
    "Next level": ["Siguiente nivel", "Niveau suivant", "Nächstes Level", "Próxima fase", "次のレベル", "다음 레벨", "下一关"],
    "Replay": ["Repetir", "Rejouer", "Nochmal", "Jogar de novo", "もう一度", "다시 하기", "重玩"],
    "Share": ["Compartir", "Partager", "Teilen", "Compartilhar", "共有", "공유", "分享"],
    "I solved level %@ of Grainfall with %lld ★": ["He resuelto el nivel %1$@ de Grainfall con %2$lld ★",
                                                   "J'ai résolu le niveau %1$@ de Grainfall avec %2$lld ★",
                                                   "Ich habe Level %1$@ in Grainfall mit %2$lld ★ gelöst",
                                                   "Resolvi a fase %1$@ de Grainfall com %2$lld ★",
                                                   "Grainfallのレベル%1$@を★%2$lldでクリア！",
                                                   "Grainfall 레벨 %1$@을(를) ★%2$lld개로 풀었어요",
                                                   "我在 Grainfall 中以 %2$lld ★ 通过了第 %1$@ 关"],
    "Ruined!": ["¡Arruinado!", "Gâché !", "Ruiniert!", "Estragou!", "台無し！", "망쳤어요!", "毁了！"],
    "%@ got into the cup.": ["%@ ha caído en el vaso.", "Du %@ est tombé dans le gobelet.", "%@ ist in den Becher geraten.",
                             "%@ caiu no copo.", "%@がカップに入ってしまった。", "%@이(가) 컵에 들어갔어요.", "%@ 掉进了杯子里。"],
    "Try again": ["Reintentar", "Réessayer", "Nochmal versuchen", "Tentar de novo", "再挑戦", "다시 시도", "再试一次"],
    "%@ cup": ["Vaso de %@", "Gobelet : %@", "Becher: %@", "Copo de %@", "%@のカップ", "%@ 컵", "%@杯"],
    "%lld of %lld": ["%1$lld de %2$lld", "%1$lld sur %2$lld", "%1$lld von %2$lld", "%1$lld de %2$lld",
                     "%2$lld中%1$lld", "%2$lld 중 %1$lld", "%1$lld/%2$lld"],
    "Grainfall Full Game": ["Grainfall: juego completo", "Grainfall : jeu complet", "Grainfall Vollversion",
                            "Grainfall: jogo completo", "Grainfall 完全版", "Grainfall 정식판", "Grainfall 完整版"],
    "Unlock every chapter: lava, stone, fire and more": [
        "Desbloquea todos los capítulos: lava, piedra, fuego y más",
        "Débloquez tous les chapitres : lave, pierre, feu et plus",
        "Alle Kapitel freischalten: Lava, Stein, Feuer und mehr",
        "Desbloqueie todos os capítulos: lava, pedra, fogo e mais",
        "全章解放：溶岩、石、炎などが登場", "모든 챕터 잠금 해제: 용암, 돌, 불 등", "解锁全部章节：熔岩、石头、火焰等"],
    "All future chapters included": ["Todos los capítulos futuros incluidos", "Tous les futurs chapitres inclus",
                                     "Alle zukünftigen Kapitel inklusive", "Todos os capítulos futuros incluídos",
                                     "今後追加される章もすべて含まれます", "앞으로 나올 챕터도 모두 포함", "包含今后所有新章节"],
    "One purchase. No ads, ever.": ["Un solo pago. Sin anuncios, nunca.", "Un seul achat. Jamais de pub.",
                                    "Einmal kaufen. Nie Werbung.", "Uma compra. Nunca terá anúncios.",
                                    "買い切り。広告は一切なし。", "한 번 구매. 광고는 절대 없음.", "一次购买，永无广告。"],
    "Shared with your family via Family Sharing": ["Compártelo con tu familia mediante En familia",
                                                   "Partagé avec votre famille via le partage familial",
                                                   "Mit deiner Familie per Familienfreigabe geteilt",
                                                   "Compartilhado com a família pelo Compartilhamento Familiar",
                                                   "ファミリー共有で家族と共有できます",
                                                   "가족 공유로 가족과 함께 사용", "可通过家人共享与家人共用"],
    "Unlock for %@": ["Desbloquear por %@", "Débloquer pour %@", "Für %@ freischalten", "Desbloquear por %@",
                      "%@で解除", "%@에 잠금 해제", "以 %@ 解锁"],
    "Unlock Full Game": ["Desbloquear juego completo", "Débloquer le jeu complet", "Vollversion freischalten",
                         "Desbloquear jogo completo", "完全版を解除", "정식판 잠금 해제", "解锁完整版"],
    "Unlocked — thank you!": ["Desbloqueado. ¡Gracias!", "Débloqué — merci !", "Freigeschaltet – danke!",
                              "Desbloqueado — obrigado!", "解除しました。ありがとう！", "잠금 해제 완료. 감사합니다!", "已解锁，感谢支持！"],
    "Restore Purchases": ["Restaurar compras", "Restaurer les achats", "Käufe wiederherstellen", "Restaurar compras",
                          "購入を復元", "구매 복원", "恢复购买"],
    "Purchase pending approval.": ["Compra pendiente de aprobación.", "Achat en attente d'approbation.",
                                   "Kauf wartet auf Freigabe.", "Compra aguardando aprovação.",
                                   "購入は承認待ちです。", "구매 승인 대기 중입니다.", "购买正在等待批准。"],
    "The store isn't available right now. Please try again later.": [
        "La tienda no está disponible ahora. Inténtalo más tarde.",
        "La boutique n'est pas disponible. Réessayez plus tard.",
        "Der Store ist gerade nicht verfügbar. Bitte versuche es später erneut.",
        "A loja não está disponível agora. Tente mais tarde.",
        "現在ストアを利用できません。後でもう一度お試しください。",
        "지금은 스토어를 사용할 수 없습니다. 나중에 다시 시도하세요.",
        "商店暂时不可用，请稍后再试。"],
    "Done": ["OK", "OK", "Fertig", "OK", "完了", "완료", "完成"],
    "Sound & feel": ["Sonido y vibración", "Son et retour haptique", "Ton & Haptik", "Som e vibração",
                     "サウンドと振動", "사운드 및 진동", "声音与触感"],
    "Sound effects": ["Efectos de sonido", "Effets sonores", "Soundeffekte", "Efeitos sonoros", "効果音", "효과음", "音效"],
    "Music": ["Música", "Musique", "Musik", "Música", "音楽", "음악", "音乐"],
    "Haptics": ["Vibración", "Retour haptique", "Haptik", "Vibração", "触覚フィードバック", "햅틱", "触感反馈"],
    "Purchases": ["Compras", "Achats", "Käufe", "Compras", "購入", "구매", "购买"],
    "Full Game unlocked": ["Juego completo desbloqueado", "Jeu complet débloqué", "Vollversion freigeschaltet",
                           "Jogo completo desbloqueado", "完全版を解除済み", "정식판 잠금 해제됨", "完整版已解锁"],
    "Progress": ["Progreso", "Progression", "Fortschritt", "Progresso", "進行状況", "진행 상황", "进度"],
    "Stars": ["Estrellas", "Étoiles", "Sterne", "Estrelas", "スター", "별", "星星"],
    "Reset Progress": ["Restablecer progreso", "Réinitialiser la progression", "Fortschritt zurücksetzen",
                       "Redefinir progresso", "進行状況をリセット", "진행 상황 초기화", "重置进度"],
    "Reset all stars and progress?": ["¿Restablecer todas las estrellas y el progreso?",
                                      "Réinitialiser toutes les étoiles et la progression ?",
                                      "Alle Sterne und den Fortschritt zurücksetzen?",
                                      "Redefinir todas as estrelas e o progresso?",
                                      "すべてのスターと進行状況をリセットしますか？",
                                      "모든 별과 진행 상황을 초기화할까요?", "要重置所有星星和进度吗？"],
    "Purchases are not affected.": ["Las compras no se ven afectadas.", "Les achats ne sont pas affectés.",
                                    "Käufe bleiben erhalten.", "As compras não são afetadas.",
                                    "購入には影響しません。", "구매 내역에는 영향이 없습니다.", "不会影响已购项目。"],
    "About": ["Información", "À propos", "Info", "Sobre", "情報", "정보", "关于"],
    "Version": ["Versión", "Version", "Version", "Versão", "バージョン", "버전", "版本"],
    "Grainfall collects no data. Your progress stays on this device.": [
        "Grainfall no recopila datos. Tu progreso se queda en este dispositivo.",
        "Grainfall ne collecte aucune donnée. Votre progression reste sur cet appareil.",
        "Grainfall sammelt keine Daten. Dein Fortschritt bleibt auf diesem Gerät.",
        "Grainfall não coleta dados. Seu progresso fica neste aparelho.",
        "Grainfallはデータを収集しません。進行状況はこの端末にのみ保存されます。",
        "Grainfall은 데이터를 수집하지 않습니다. 진행 상황은 이 기기에만 저장됩니다.",
        "Grainfall 不收集任何数据。你的进度只保存在此设备上。"],
    "Sound and music are generated live on your device.": [
        "El sonido y la música se generan en tiempo real en tu dispositivo.",
        "Le son et la musique sont générés en direct sur votre appareil.",
        "Sound und Musik entstehen live auf deinem Gerät.",
        "O som e a música são gerados ao vivo no seu aparelho.",
        "サウンドと音楽は端末上でリアルタイムに生成されます。",
        "사운드와 음악은 기기에서 실시간으로 생성됩니다.",
        "音效和音乐均在你的设备上实时生成。"],
    "Game board": ["Tablero de juego", "Plateau de jeu", "Spielfeld", "Tabuleiro", "ゲーム盤", "게임 보드", "游戏棋盘"],
    "Drag to dig through dirt. Tap a striped gate to open it.": [
        "Arrastra para cavar en la tierra. Toca una compuerta a rayas para abrirla.",
        "Glissez pour creuser la terre. Touchez une vanne rayée pour l'ouvrir.",
        "Ziehe, um durch Erde zu graben. Tippe auf eine gestreifte Klappe, um sie zu öffnen.",
        "Arraste para cavar a terra. Toque numa comporta listrada para abri-la.",
        "ドラッグで土を掘る。しま模様のゲートをタップで開く。",
        "드래그해서 흙을 파세요. 줄무늬 게이트를 탭하면 열립니다.",
        "拖动挖开泥土。点按条纹闸门将其打开。"],
    # Materials (String(localized:) in Theme.swift)
    "Sand": ["Arena", "Sable", "Sand", "Areia", "砂", "모래", "沙子"],
    "Water": ["Agua", "Eau", "Wasser", "Água", "水", "물", "水"],
    "Lava": ["Lava", "Lave", "Lava", "Lava", "溶岩", "용암", "熔岩"],
    "Stone": ["Piedra", "Pierre", "Stein", "Pedra", "石", "돌", "石头"],
    "Steam": ["Vapor", "Vapeur", "Dampf", "Vapor", "蒸気", "증기", "蒸汽"],
    "Plant": ["Planta", "Plante", "Pflanze", "Planta", "植物", "식물", "植物"],
    "Fire": ["Fuego", "Feu", "Feuer", "Fogo", "炎", "불", "火"],
    "Dirt": ["Tierra", "Terre", "Erde", "Terra", "土", "흙", "泥土"],
    "Wall": ["Muro", "Mur", "Wand", "Parede", "壁", "벽", "墙"],
    "Gate": ["Compuerta", "Vanne", "Klappe", "Comporta", "ゲート", "게이트", "闸门"],
    "Drain": ["Desagüe", "Siphon", "Abfluss", "Ralo", "排水口", "배수구", "排水口"],
}


def entry(translations):
    return {"localizations": {lang: {"stringUnit": {"state": "translated", "value": value}}
                              for lang, value in translations.items() if value}}


def main():
    strings = {}
    for key, values in UI.items():
        assert len(values) == len(LANGS), key
        strings[key] = entry(dict(zip(LANGS, values)))

    levels_file = ROOT / "tools/l10n/levels.json"
    if levels_file.exists():
        for key, per_lang in json.loads(levels_file.read_text()).items():
            strings.setdefault(key, entry({l: per_lang.get(l, "") for l in LANGS}))

    catalog = {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}
    out = ROOT / "App/Resources/Localizable.xcstrings"
    out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    print(f"wrote {out} — {len(strings)} keys × {len(LANGS)} languages")


if __name__ == "__main__":
    main()
