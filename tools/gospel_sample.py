"""복음 메시지 예시 (5문장 × 7개 언어) — SQL 시드와 데모 데이터의 공통 원본.

⚠️ 예시 번역입니다. 발족식 전에 각 나라 현지 사역자가 검수한 문장으로 교체하세요
   (앱의 관리 → 훈련 → 복음 메시지 문장에서 바로 고칠 수 있습니다).
사용: python3 tools/gospel_sample.py sql   → 03_국가_시드.sql 에 넣을 SQL 출력
      python3 tools/gospel_sample.py js    → app/index.html 데모 데이터(JSON) 출력
"""
import json, sys

TITLE = 'The Good News (sample)'
BASE = [  # (seq, English meaning, Korean meaning)
    (1, 'God loves you.', '하나님은 당신을 사랑하십니다.'),
    (2, 'All people have sinned and are separated from God.', '모든 사람은 죄를 지어 하나님과 멀어졌습니다.'),
    (3, 'Jesus died on the cross for our sins and rose again.', '예수님은 우리 죄를 위해 십자가에서 죽으시고 다시 살아나셨습니다.'),
    (4, 'If you believe in Jesus, you receive forgiveness and eternal life.', '예수님을 믿으면 죄 용서와 영원한 생명을 받습니다.'),
    (5, 'Will you receive Jesus today?', '오늘 예수님을 영접하시겠어요?'),
]
LOCAL = {  # code → [(local text, pronunciation)] in seq order
    'KR': [
        ('하나님은 당신을 사랑하십니다.', 'Hananim-eun dangsin-eul saranghasimnida.'),
        ('모든 사람은 죄를 지어 하나님과 멀어졌습니다.', 'Modeun saram-eun joe-reul jieo Hananim-gwa meoreojyeotseumnida.'),
        ('예수님은 우리 죄를 위해 십자가에서 죽으시고 다시 살아나셨습니다.', 'Yesunim-eun uri joe-reul wihae sipjaga-eseo jugeusigo dasi sarananasyeotseumnida.'),
        ('예수님을 믿으면 죄 용서와 영원한 생명을 받습니다.', 'Yesunim-eul mideumyeon joe yongseo-wa yeongwonhan saengmyeong-eul batseumnida.'),
        ('오늘 예수님을 영접하시겠어요?', 'Oneul Yesunim-eul yeongjeophasigesseoyo?'),
    ],
    'PH': [
        ('Mahal ka ng Diyos.', 'ma-HAL ka nang dee-YOS'),
        ('Lahat ng tao ay nagkasala at nahiwalay sa Diyos.', 'la-HAT nang TA-o ai nag-ka-sa-LA at na-hi-wa-LAI sa dee-YOS'),
        ('Si Hesus ay namatay sa krus para sa ating mga kasalanan at muling nabuhay.', 'see HE-sus ai na-ma-TAI sa KROOS PA-ra sa A-ting ma-NGA ka-sa-LA-nan at MOO-ling na-BOO-hai'),
        ('Kung sasampalataya ka kay Hesus, tatanggap ka ng kapatawaran at buhay na walang hanggan.', 'kung sa-sam-pa-la-ta-YA ka kai HE-sus, ta-tang-GAP ka nang ka-pa-ta-WA-ran at BOO-hai na wa-LANG hang-GAN'),
        ('Tatanggapin mo ba si Hesus ngayon?', 'ta-tang-GA-pin mo ba see HE-sus nga-YON?'),
    ],
    'MY': [
        ('Tuhan mengasihi anda.', 'TOO-han meng-a-SEE-hee AN-da'),
        ('Semua manusia telah berdosa dan terpisah daripada Tuhan.', 'se-MOO-a ma-NOO-sia te-LAH ber-DO-sa dan ter-PEE-sah da-ree-PA-da TOO-han'),
        ('Yesus mati di kayu salib kerana dosa-dosa kita dan bangkit semula.', 'YE-sus MA-tee dee KA-yoo SA-lib ke-RA-na DO-sa DO-sa KEE-ta dan BANG-kit se-MOO-la'),
        ('Jika anda percaya kepada Yesus, anda menerima pengampunan dan hidup yang kekal.', 'JEE-ka AN-da per-CHA-ya ke-PA-da YE-sus, AN-da me-ne-REE-ma peng-am-POO-nan dan HEE-dup yang ke-KAL'),
        ('Adakah anda mahu menerima Yesus hari ini?', 'a-DA-kah AN-da MA-hoo me-ne-REE-ma YE-sus HA-ree EE-nee?'),
    ],
    'TH': [
        ('พระเจ้าทรงรักคุณ', 'Phra-jao song rak khun'),
        ('ทุกคนทำบาปและแยกจากพระเจ้า', 'Thuk khon tham baap lae yaek jaak Phra-jao'),
        ('พระเยซูสิ้นพระชนม์บนไม้กางเขนเพื่อบาปของเรา และทรงเป็นขึ้นมาใหม่', 'Phra-Yesu sin phra-chon bon mai-kaang-khen phuea baap khong rao, lae song pen khuen maa mai'),
        ('ถ้าคุณเชื่อในพระเยซู คุณจะได้รับการอภัยบาปและชีวิตนิรันดร์', 'Thaa khun chuea nai Phra-Yesu, khun ja dai rap kaan a-phai baap lae chii-wit ni-ran'),
        ('วันนี้คุณจะรับพระเยซูไหม', 'Wan-nii khun ja rap Phra-Yesu mai?'),
    ],
    'MX': [
        ('Dios te ama.', 'DYOS teh AH-mah'),
        ('Todos hemos pecado y estamos separados de Dios.', 'TOH-dohs EH-mohs peh-KAH-doh ee ehs-TAH-mohs seh-pah-RAH-dohs deh DYOS'),
        ('Jesús murió en la cruz por nuestros pecados y resucitó.', 'heh-SOOS moo-RYOH ehn lah KROOS pohr NWEHS-trohs peh-KAH-dohs ee reh-soo-see-TOH'),
        ('Si crees en Jesús, recibes el perdón y la vida eterna.', 'see KREH-ehs ehn heh-SOOS, reh-SEE-behs ehl pehr-DOHN ee lah VEE-dah eh-TEHR-nah'),
        ('¿Quieres recibir a Jesús hoy?', 'KYEH-rehs reh-see-BEER ah heh-SOOS oy?'),
    ],
    'JP': [
        ('神様はあなたを愛しています。', 'Kamisama wa anata o aishite imasu.'),
        ('すべての人は罪を犯し、神様から離れています。', 'Subete no hito wa tsumi o okashi, Kamisama kara hanarete imasu.'),
        ('イエス様は私たちの罪のために十字架で死に、よみがえられました。', 'Iesu-sama wa watashitachi no tsumi no tame ni jūjika de shini, yomigaeraremashita.'),
        ('イエス様を信じるなら、罪の赦しと永遠のいのちを受けます。', 'Iesu-sama o shinjiru nara, tsumi no yurushi to eien no inochi o ukemasu.'),
        ('今日、イエス様を受け入れますか？', 'Kyō, Iesu-sama o ukeiremasu ka?'),
    ],
    'EG': [
        ('ربنا بيحبك.', 'Rabbena biyḥebbak.'),
        ('كل الناس أخطأوا وبعدوا عن ربنا.', 'Koll en-nās akhṭa’u we be‘du ‘an Rabbena.'),
        ('يسوع مات على الصليب علشان خطايانا وقام من الأموات.', 'Yasū‘ māt ‘ala eṣ-ṣalīb ‘ashān khaṭayāna we ’ām men el-amwāt.'),
        ('لو آمنت بيسوع، هتاخد غفران الخطايا والحياة الأبدية.', 'Law āmant be-Yasū‘, hatākhod ghofrān el-khaṭāya wel-ḥayāh el-abadeyya.'),
        ('تحب تقبل يسوع النهارده؟', 'Teḥebb te’bal Yasū‘ en-nahārda?'),
    ],
}

def q(s): return "'" + s.replace("'", "''") + "'"

def sql():
    base = ',\n    '.join(f"({n}, {q(en)}, {q(ko)})" for n, en, ko in BASE)
    loc = ',\n    '.join(f"({q(code)}, {i + 1}, {q(t)}, {q(p)})" for code, rows in LOCAL.items() for i, (t, p) in enumerate(rows))
    return f"""-- ③ 언어 훈련: 복음 메시지 예시 (5문장 × 7개 언어) — tools/gospel_sample.py 로 생성
--   ⚠️ 예시 번역입니다. 현지 사역자가 검수한 문장으로 바꾸세요 (앱: 관리 → 훈련 → 복음 메시지 문장)
insert into public.gospel_messages (title, base_text, sort_order)
select {q(TITLE)}, {q(' '.join(en for _, en, _ in BASE))}, 1
where not exists (select 1 from public.gospel_messages);

with m as (select id from public.gospel_messages order by sort_order, id limit 1),
base(seq, en, ko) as (values
    {base}),
loc(code, seq, local_text, pron) as (values
    {loc})
insert into public.gospel_sentences (message_id, country_id, seq, source_text, source_ko, local_text, pronunciation)
select m.id, c.id, b.seq, b.en, b.ko, l.local_text, l.pron
from m cross join base b
join loc l on l.seq = b.seq
join public.countries c on c.code = l.code
where not exists (select 1 from public.gospel_sentences s where s.message_id = m.id and s.country_id = c.id);
"""

def js():
    return json.dumps({'title': TITLE, 'base': BASE, 'local': LOCAL}, ensure_ascii=False, separators=(',', ':'))

if __name__ == '__main__':
    print(sql() if sys.argv[1:] == ['sql'] else js())
