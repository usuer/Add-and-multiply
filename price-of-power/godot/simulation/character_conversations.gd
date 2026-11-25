class_name CharacterConversations
extends Resource

const LOCATION_CAST: Dictionary = {
	"castle": ["spouse", "sister", "secretary", "borin"],
	"barracks": ["radomir", "daren"],
	"market": ["zlata", "miron", "aglaia"],
	"school": ["tikhon"],
	"temple": ["savva"],
	"embassy": ["vardan"]
}

const PROFILES: Dictionary = {
	"spouse": {"role": "Княгиня и мать наследников", "prompt": "Элина ждёт минуты без советников. Она хочет понять, осталось ли у семьи место среди государственных дел.", "opening": "Я не прошу тебя забыть о княжестве. Прошу только не вспоминать о нас последними."},
	"sister": {"role": "Сестра князя и посредник областей", "prompt": "Лада принесла письма старост и хочет говорить не как проситель, а как человек, который знает деревни лично.", "opening": "В книгах область — три строки. Для меня это люди, у которых я ночевала и ела за одним столом."},
	"secretary": {"role": "Личный секретарь", "prompt": "Марек закончил разбирать старые приказы и отделил ошибки писцов от намеренных исправлений.", "opening": "Я могу дать вам удобный ответ сегодня или точный через два дня. Одновременно не получится."},
	"borin": {"role": "Казначей", "prompt": "Борин пришёл с двумя вариантами расходов и заранее недоволен обоими.", "opening": "Деньги не решают, кто прав. Они лишь показывают, чьё решение мы действительно можем исполнить."},
	"radomir": {"role": "Воевода полевого войска", "prompt": "Радомир проверяет караулы и готов говорить о границе без церемоний.", "opening": "Если хотите спокойствия — я совру, что всё под контролем. Если хотите подготовиться — доставайте карту."},
	"daren": {"role": "Начальник городской стражи", "prompt": "Дарен принёс список людей, которых можно задержать, но доказательств пока недостаточно.", "opening": "Я могу очистить улицу за час. Сделать так, чтобы она после этого снова доверяла страже, гораздо труднее."},
	"zlata": {"role": "Владелица мастерских", "prompt": "Злата говорит от имени нанимателей и работников, хотя их интересы совпадают не всегда.", "opening": "Мастерская стоит не тогда, когда нет железа. Она стоит, когда хозяин и люди перестают верить одной ведомости."},
	"miron": {"role": "Бывший судья и оратор", "prompt": "Мирон согласен говорить без толпы, но не обещает быть удобнее, чем на площади.", "opening": "Я пришёл не доказывать, что вы плохой князь. Я пришёл проверить, можно ли при вас задавать плохие вопросы."},
	"aglaia": {"role": "Хозяйка Дома семи фонарей", "prompt": "Аглая знает, кто встречался в городе ночью, но каждое имя затрагивает чью-то семью или карьеру.", "opening": "Люди откровенны там, где уверены, что их не судят. Поэтому я слышу то, чего не услышит ваша стража."},
	"tikhon": {"role": "Изобретатель", "prompt": "Тихон принёс деталь нового насоса и явно забыл, что разговор назначен не только ради неё.", "opening": "Он снова течёт. Это хорошая новость: теперь я хотя бы знаю, где именно ошибся."},
	"savva": {"role": "Дворцовый писец", "prompt": "Савва боится и наказания, и тех, кто оплатил побег его брата. Он готов говорить, если поймёт, что его слушают.", "opening": "Я украл печать. Но приказ, который вы нашли, — не тот приказ, ради которого я её брал."},
	"vardan": {"role": "Речной торговец и хозяин частной сети", "prompt": "Вардан пришёл без оружия, но за его словами стоят склады, лодки и люди.", "opening": "Вы называете моих людей преступниками. Ваш отец называл их способом сделать то, чего не мог приказать открыто."}
}

const OPTIONS: Dictionary = {
	"spouse": {
		"listen": {"title": "Спросить, что сейчас тревожит семью", "response": "Элина говорит о бессоннице Всеволода и о том, что Милица стала прятать письма, подражая взрослым. Ей нужна не казна, а предсказуемость дома.", "changes": {"trust": 2}},
		"share": {"title": "Рассказать, чего вы сами боитесь", "response": "Она не предлагает решения и впервые за разговор не говорит как княгиня. Теперь Элина знает, какую угрозу вы считаете настоящей.", "changes": {"affection": 2, "trust": 2}},
		"duty": {"title": "Попросить её пока не отвлекать от управления", "response": "Элина кивает и переходит на официальный тон. Просьбу она исполнила; близости этот разговор не добавил.", "changes": {"trust": -2, "resentment": 2}},
		"new_guard_at_home": {
			"title": "Спросить Элину, как дети привыкли к новой охране",
			"lead": "Элина хочет поговорить после смены охраны",
			"response": "«Милица спросила, куда делся Степан. Он каждый вечер давал ей ключ, чтобы она сама заперла дверь. Я сказала, что его перевели. Познакомь её с новым караулом, ладно? При тебе она не будет бояться подойти».",
			"requires_event": "family_warning",
			"requires_choices": ["double_guard"],
			"changes": {"trust": 2, "affection": 1}
		},
		"apologize_to_elina": {
			"title": "Признать перед Элиной, что нельзя было рисковать Всеволодом",
			"lead": "Элина ждёт разговора о случившемся в детской",
			"response": "«Он думает, что прачку схватили, потому что он не сумел спрятать воск. Я два вечера объясняла ему, что он не виноват. Теперь скажи ему сам. А со мной мы об этом ещё поговорим».",
			"requires_event": "family_warning",
			"requires_choices": ["bait"],
			"changes": {"trust": 1, "resentment": -1}
		}
	},
	"sister": {
		"names": {"title": "Попросить назвать конкретных старост и деревни", "response": "Лада перечисляет людей, сроки запасов и дорогу, которую размоет первой. Жалоба превращается в проверяемый список.", "changes": {"respect": 2}},
		"challenge": {"title": "Спросить, кто из старост может лгать", "response": "Она сердится, но называет одного: он преувеличивает потери, чтобы первым получить зерно. Остальным Лада верит.", "changes": {"respect": 1}},
		"promise": {"title": "Обещать помочь всем без дополнительной проверки", "response": "Лада благодарит, но спрашивает, из какого амбара придёт помощь. Одного обещания для неё уже недостаточно.", "changes": {"trust": -1}}
	},
	"secretary": {
		"method": {"title": "Попросить объяснить ход проверки", "response": "Марек показывает три почерка и две даты. Он отделяет то, что знает, от предположения и указывает, какую запись нужно найти следующей.", "changes": {"respect": 2}},
		"pressure": {"title": "Потребовать имя виновного сегодня", "response": "Марек называет самого вероятного человека, затем предупреждает: это версия, которую легко опровергнет хороший защитник.", "changes": {"trust": -2}},
		"protect": {"title": "Разрешить докладывать неприятные выводы без смягчения", "response": "Он уточняет, распространяется ли это на вашу семью. Получив подтверждение, Марек запирает черновики в личном ящике.", "changes": {"trust": 3}},
		"keep_copy": {
			"title": "Попросить Марека сохранить копию записи о переводе заключённого",
			"lead": "Марек может найти запись о переводе заключённого",
			"response": "«В журнале у ворот стоит час, когда взяли ключ. Я перепишу строку при караульном и попрошу его расписаться. Если Савва заговорит, будет с чем сверить». К вечеру Марек приносит лист с подписью караульного.",
			"requires_facts": {"second_seal_investigation": "quiet"},
			"closes_after": "savva_at_chapel",
			"sets_facts": {"marek_copy_saved": true},
			"changes": {"respect": 2}
		}
	},
	"borin": {
		"ledger": {"title": "Разобрать один платёж от начала до конца", "response": "Борин проводит пальцем от налога до расходной ведомости и показывает место, где деньги стали лишь записью без получателя.", "changes": {"respect": 2}},
		"tempt": {"title": "Спросить, как проще скрыть чрезвычайный расход", "response": "Он отвечает слишком быстро: провести через ремонт стен. Затем понимает, что сказал, и внимательно смотрит на вас.", "changes": {"trust": 2}},
		"audit": {"title": "Предупредить о независимой проверке казны", "response": "Борин бледнеет, но просит проверять и семейную казну: иначе результат заранее сочтут политическим.", "changes": {"respect": 1, "resentment": 1}}
	},
	"radomir": {
		"truth": {"title": "Попросить оценку без успокаивающих слов", "response": "Радомир говорит прямо: стен хватит, людей — нет. Если ударят одновременно по воротам и складам, придётся выбирать.", "changes": {"trust": 2, "respect": 2}},
		"soldiers": {"title": "Спросить, чего боятся солдаты", "response": "Не смерти, отвечает он. Они боятся получить два разных приказа и после боя оказаться виноватыми при любом исходе.", "changes": {"respect": 2}},
		"obedience": {"title": "Напомнить, что воевода обязан только подчиняться", "response": "Радомир отвечает по уставу и прекращает спор. Отныне он будет исполнять формулировку приказа, а не искать ваш замысел.", "changes": {"trust": -3, "resentment": 2}},
		"handover": {
			"title": "Попросить Радомира проверять передачу приказов вместе со стражей",
			"lead": "С Радомиром можно обсудить связь между караулами",
			"response": "«На прошлой смене мой связной бегал между караулками, пока его не узнали в лицо. Попрошу Дарена прислать двоих. Пусть попробуют передать нам приказ от ворот до казарм». К вечеру Радомир докладывает, что оба караула отработали передачу.",
			"requires_event": "border_courier",
			"requires_choices": ["scouts", "envoy", "dismiss"],
			"closes_after": "divided_command",
			"sets_facts": {"radomir_handover_ready": true},
			"changes": {"trust": 2}
		}
	},
	"daren": {
		"evidence": {"title": "Отделить подозрения от доказательств", "response": "Дарен вычёркивает половину списка. Оставшиеся опаснее, зато теперь понятно, за что каждого можно допрашивать.", "changes": {"respect": 2}},
		"streets": {"title": "Спросить, кому доверяют городские кварталы", "response": "Он называет не чиновников, а пекаря, банщика и двух вдов. Через них стража узнаёт о беспорядках раньше доносов.", "changes": {"trust": 2}},
		"sweep": {"title": "Разрешить задержать всех подозреваемых", "response": "Дарен просит письменный приказ. Он выполнит его, но заранее оставляет доказательство, кто принял решение.", "changes": {"trust": 1, "resentment": 1}}
	},
	"zlata": {
		"workers": {"title": "Спросить, чего хотят работники кроме жалованья", "response": "Чтобы ведомость при них читали вслух, отвечает Злата. Люди готовы терпеть задержку, но не исчезновение денег без объяснения.", "changes": {"respect": 2}},
		"power": {"title": "Спросить, какую власть она хочет получить", "response": "Право видеть государственный заказ до подписи казначея. Это даст ей влияние — и позволит ловить двойные счета.", "changes": {"trust": 2}},
		"threat": {"title": "Предупредить, что князь может сменить владельцев мастерских", "response": "Злата спокойно отвечает, что владельца сменить можно за день, а восемьдесят мастеров уйдут за ворота за вечер.", "changes": {"trust": -3, "resentment": 3}}
	},
	"miron": {
		"goal": {"title": "Спросить, чего он добивается публичными речами", "response": "Чтобы следующий приказ пришлось объяснять до беспорядков, а не после. Должность он не просит — пока.", "changes": {"respect": 2}},
		"limit": {"title": "Спросить, признаёт ли он предел критике во время войны", "response": "Да: он не назовёт расположение войск. Но кражу провианта войной прикрыть не позволит.", "changes": {"trust": 1, "respect": 1}},
		"silence": {"title": "Предложить место в совете в обмен на молчание", "response": "Мирон спрашивает, нужен вам советник или купленный свидетель. Ответа он не требует: вопрос уже прозвучал.", "changes": {"trust": -3, "resentment": 2}},
		"public_witnesses": {
			"title": "Попросить Мирона найти свидетелей для проверки спорных приказов",
			"lead": "Мирон может найти свидетелей среди старшин",
			"response": "«На площади вы дали мне договорить. Я спрошу у двух старшин, были ли они там. Если согласятся, пусть сами смотрят книги и говорят, что видели». К вечеру к Мирону приходят старшины кожевников и мельников. Оба готовы выступить при людях.",
			"requires_event": "market_speech",
			"requires_choices": ["listen", "answer"],
			"closes_after": "night_of_second_seal",
			"sets_facts": {"miron_public_witnesses": true},
			"changes": {"respect": 2}
		}
	},
	"aglaia": {
		"price": {"title": "Спросить, чего она хочет за сведения", "response": "Не денег. Она хочет, чтобы стража перестала считать каждую её работницу удобной подозреваемой без права на свидетеля.", "changes": {"respect": 2}},
		"guest": {"title": "Попросить описать приезжего, не называя имени", "response": "Аглая описывает манеры, грязь на сапогах и северный способ завязывать кошель. Этого достаточно, чтобы искать человека, а не слух.", "requires_facts": {"aglaia_grey_guest": true}, "changes": {"trust": 2}},
		"flirt": {"title": "Предложить Аглае встретиться без свиты", "response": "Аглая задерживает взгляд. «Вы хотите поговорить о страже или о чём-то другом? Мне нужно знать, кого ещё звать». Она отходит к прилавку, не дожидаясь ответа.", "changes": {"affection": 3, "respect": -2}},
		"thank_aglaia": {
			"title": "Поблагодарить Аглаю за помощь на закрытом вечере",
			"lead": "Аглая может рассказать, что было после вашего ухода",
			"response": "«Пожалуйста. Только Дарен уже приходил. Спрашивал у Лиды, кто вышел через кухню. Она сделала вид, что не поняла. Имейте в виду: для вас это был один вечер, а ей завтра снова стоять у той двери».",
			"requires_event": "aglaia_invitation",
			"requires_choices": ["attend"],
			"changes": {"trust": 1, "respect": 1}
		},
		"ask_about_agent": {
			"title": "Спросить Аглаю, чем ваш наблюдатель выдал себя",
			"lead": "Аглая видела, чем наблюдатель привлёк внимание",
			"response": "«Играл и ни разу не посмотрел, что выпало. Купец предложил ему поставить, а он опять за своё: когда пойдут обозы? Я посадила рядом Лиду, чтобы сменить разговор. Теперь купец думает, что она вам помогает».",
			"requires_event": "aglaia_invitation",
			"requires_choices": ["agent"],
			"changes": {"respect": 2}
		},
		"after_declining": {
			"title": "Спросить Аглаю, осталась ли возможность договариваться",
			"lead": "С Аглаей можно поговорить после отказа от приглашения",
			"response": "«Можно. Мне даже проще, что вы сказали сразу. Лида уже поставила для вас кубок. Я велела убрать. Если в следующий раз придёте по делу, так и скажите, при всех».",
			"requires_event": "aglaia_invitation",
			"requires_choices": ["decline"],
			"changes": {"respect": 1}
		}
	},
	"tikhon": {
		"failure": {"title": "Попросить показать главную ошибку машины", "response": "Тихон с облегчением разбирает клапан и объясняет без высоких слов: кожа разбухает, ход поршня меняется, вода уходит назад.", "changes": {"trust": 2, "respect": 2}},
		"use": {"title": "Спросить, кому насос поможет первым", "response": "Не дворцу. Красильням и нижним дворам, где чистую воду носят снизу вёдрами. Он явно ждал другого ответа от себя самого.", "changes": {"respect": 2}},
		"mock": {"title": "Пошутить, что машина снова течёт", "response": "Тихон смеётся вместе с вами, но сворачивает чертёж раньше времени. Следующую ошибку он, вероятно, будет исправлять без княжеского двора.", "changes": {"trust": -3, "resentment": 2}},
		"prepare_trial": {
			"title": "Попросить Тихона показать, как он проверит насос",
			"lead": "Тихон готов показать пробное испытание насоса",
			"response": "Тихон ставит на стол два ведра. «Из этого пьют сейчас. Из этого смогут пить, если забор поднять выше стоков. Я проверял только, поднимет ли машина воду». Вы договариваетесь, что лекари будут сравнивать обе пробы и смогут остановить испытание.",
			"requires_event": "fever_outbreak",
			"requires_choices": ["clinics", "quarantine", "conceal", "neglected"],
			"closes_after": "tikhon_pump",
			"sets_facts": {"tikhon_trial_prepared": true},
			"changes": {"trust": 3, "respect": 1}
		}
	},
	"savva": {
		"brother": {"title": "Спросить сначала о брате, а не о печати", "response": "Савва объясняет: брат сидел за долг, не за заговор. Именно поэтому поддельный приказ казался ему меньшим злом.", "changes": {"trust": 3}},
		"seal": {"title": "Попросить восстановить весь путь печати", "response": "Он называет шкаф, ключ, первую подделку и момент, когда сумка оказалась у людей Вардана. В рассказе остаётся одна ночь без свидетелей.", "changes": {"respect": 2}},
		"punish": {"title": "Пообещать суд независимо от сотрудничества", "response": "Савва перестаёт просить прощения и говорит точнее. Он понял цену признания и больше не пытается угадать желаемый ответ.", "changes": {"trust": -1, "respect": 2}}
	},
	"vardan": {
		"father": {"title": "Спросить, что именно поручал ему отец", "response": "Подкупить двух офицеров, сорвать поставку и заплатить семьям тех, кого нельзя было признать своими людьми. Вардан называет суммы без запинки.", "changes": {"respect": 2}},
		"network": {"title": "Спросить, кому подчиняются его люди", "response": "Тому, кто обеспечивает работу и защищает семьи. Вардан не произносит «мне», потому что считает ответ очевидным.", "changes": {"trust": 1}},
		"threat": {"title": "Сказать, что его сеть будет уничтожена", "response": "Он не спорит. Лишь спрашивает, кто после этого разгрузит зерно, проведёт лодки и найдёт людей, которых нет в ваших списках.", "changes": {"resentment": 4, "grievance": 3}}
	}
}

const CITY_CASES: Dictionary = {
	"sister": {
		"fact": "lowland_register", "start_cycle": 2, "end_cycle": 7,
		"requires_facts": {"father_funeral_completed": true}, "closes_after": "market_speech",
		"lead": "Лада привезла две ведомости из Долинной области",
		"setup": "Лада кладёт на стол две ведомости. «Смотри: писец отметил по пять мер на двор, а в деревне расписывались за три. Могу привести свидетелей. Только староста узнает их по именам».",
		"options": {
			"lowland_register_open": {
				"title": "Сверить списки при свидетелях и вывесить итог",
				"response": "Лада перечёркивает имена перед тем, как отдать копию глашатаю. В деревнях теперь знают, сколько зерна им причиталось. Один из владельцев амбаров требует объяснить, почему его книгу показывают на площади.",
				"outcome": "open", "changes": {"respect": 2},
				"faction_changes": {"rural": 3, "nobility": -2},
				"reaction": "Сверку долинных выдач провели при свидетелях и вывесили итог на площади."
			},
			"lowland_register_sealed": {
				"title": "Передать сверку Мареку и пока оставить её в канцелярии",
				"response": "«Так людей я тебе приведу», — говорит Лада и забирает копию с именами. Марек получает подписанный результат. За воротами по-прежнему спорят о недостаче: людям никто не сказал, кто и что проверял.",
				"outcome": "sealed", "changes": {"trust": 3}
			}
		}
	},
	"zlata": {
		"fact": "workshop_shift", "start_cycle": 5, "end_cycle": 9,
		"requires_event": "smiths_dispute", "requires_choices": ["mediate", "pay", "seize", "neglected"],
		"lead": "Злата просит разобрать спор за место у горна",
		"setup": "«У меня один целый горн и две смены. Мастера гонят подмастерьев на вечер, а утром велят снова быть у огня. При всех спорить с мастером они не станут. Решите, кто теперь ведёт очередь».",
		"options": {
			"workshop_shift_shared": {
				"title": "Дать каждой смене выбирать старшего и вести общую очередь",
				"response": "Подмастерье впервые сам записал очередь на доске. Мастера согласились, но задержали утреннюю работу, пока не увидели в списке свой заказ. Злата просит вас прийти через неделю, если очередь снова будут менять ночью.",
				"outcome": "shared", "changes": {"respect": 2},
				"faction_changes": {"guilds": 2},
				"reaction": "Обе смены в мастерских получили голос при распределении времени у горна."
			},
			"workshop_shift_foremen": {
				"title": "Оставить очередь Злате, но велеть объявлять её с утра",
				"response": "Злата записывает на день вперёд, кто встанет к горну, и вывешивает доску сама. К полудню молоты снова слышны с улицы. Подмастерья знают часы, но жалуются, что их расчёт всё равно обсуждали без них.",
				"outcome": "foremen", "changes": {"trust": 2}, "order_change": 2,
				"faction_changes": {"guilds": -1},
				"reaction": "Очередь у горна объявили заранее, но подмастерьев к её составлению не допустили."
			}
		}
	},
	"daren": {
		"fact": "market_watch", "start_cycle": 8, "end_cycle": 12,
		"requires_event": "market_speech", "requires_choices": ["listen", "answer", "disperse", "neglected"],
		"lead": "Дарен ищет способ вернуть порядок на рынке",
		"setup": "Дарен показывает вам сломанный замок от прилавка. «Третью неделю таскают мешки. Лавочники предлагают встречать приезжих сами и записывать, кто за кого поручился. Или я оставлю людей проверять вывоз товара после закрытия. На оба дела людей нет».",
		"options": {
			"market_watch_neighbors": {
				"title": "Поручить лавочникам вести список знакомых возчиков",
				"response": "Лавочники быстро узнали двоих, что возили мешки без хозяев. Теперь у караула есть к кому обратиться. Но один приезжий возчик жалуется Дарену: гильдейский старшина согласился поручиться, только если он снизит цену.",
				"outcome": "neighbors", "changes": {"respect": 2}, "order_change": 1,
				"faction_changes": {"guilds": 2},
				"reaction": "На рынке лавочники стали поручаться за возчиков и помогать караулу разбираться в спорных вывозах."
			},
			"market_watch_inspectors": {
				"title": "Оставить вход свободным и проверять вывоз товара вечером",
				"response": "Караул нашёл пропавшие мешки в телеге под пустыми лотками. Теперь на закрытие приезжают заранее: проверка здорово задерживает торговцев, а последнюю телегу вчера выпустили уже в темноте.",
				"outcome": "inspectors", "changes": {"trust": 2}, "order_change": 3,
				"faction_changes": {"guilds": -2},
				"reaction": "Вечерние проверки на выезде с рынка вернули часть краденого, но задерживают торговцев."
			}
		}
	},
	"borin": {
		"fact": "pier_arrears", "start_cycle": 10, "end_cycle": 14,
		"lead": "Борин принёс долговую дощечку с пристани",
		"setup": "Казначей кладёт перед вами долговую дощечку. «Артель год не платила за причал. Деньги у них появились только сейчас. Могу взять причитающееся. Могу зачесть железные скобы, которые они уже привезли для ремонта пристани».",
		"options": {
			"pier_arrears_collect": {
				"title": "Взыскать просроченную плату по договору",
				"response": "Четыре монеты вернулись в казну. Старший артели отсчитал их при Борине. Тот записал выплату, а ремонтники сняли с пристани табличку со сроком работ: скоб им так и не выдали.",
				"outcome": "collected", "gold_change": 4, "changes": {"respect": 2},
				"faction_changes": {"guilds": -2},
				"reaction": "С артелей взыскали просроченную плату за пристань, а её ремонт пришлось отложить."
			},
			"pier_arrears_in_kind": {
				"title": "Принять скобы в счёт долга и закрепить сходни",
				"response": "Ремонтники за день закрепили шаткие сходни. По ним снова катят бочки, не перенося груз по одной. Борин вычёркивает долг и записывает, кто принял железо: «Пусть потом не скажут, что я просто простил недостачу».",
				"outcome": "in_kind", "changes": {"trust": 1}, "order_change": 2,
				"faction_changes": {"guilds": 2},
				"reaction": "Скобы приняли в счёт арендного долга, и пристань смогла возобновить разгрузку бочек."
			}
		}
	},
	"radomir": {
		"fact": "ridge_rotation", "start_cycle": 13, "end_cycle": 16, "closes_after": "divided_command",
		"lead": "Радомир просит решить, когда сменить дальний караул",
		"setup": "«Смена у дальнего караула завтра. Двое просятся домой — жать хлеб, и у обоих поле на двоих с матерью. Замена знает дорогу до холма, но не знает боковых троп. Одних я могу отправить, пока вторые вводят смену».",
		"options": {
			"ridge_rotation_partial": {
				"title": "Сменить караул в два приёма, начав с тех, кто нужен дома",
				"response": "Двух дозорных отпустили к семьям. Остальные показали смене тропы и вернулись позже обещанного. Радомир говорит, что караул теперь знает местность, но в следующий раз попросит утвердить срок прежде, чем обещать его людям.",
				"outcome": "partial", "changes": {"respect": 2},
				"faction_changes": {"rural": 1, "military": 1},
				"reaction": "Дальний караул сменили в два приёма, чтобы не оставить посты без проводников."
			},
			"ridge_rotation_on_time": {
				"title": "Сменить весь караул в обещанный день",
				"response": "Людей отпустили вовремя. Ночью новый караул пропустил обоз, приняв колею за срез на соседний холм. Утром Радомир сам провёл смену по тропам. Из деревень уже пришло спасибо за то, что князь сдержал срок.",
				"outcome": "on_time", "changes": {"trust": 2},
				"faction_changes": {"rural": 3, "military": -1},
				"reaction": "Дозорные вернулись к семьям точно в срок, а смене пришлось осваивать боковые тропы."
			}
		}
	}
}

@export var discussed: Dictionary = {}
@export var last_topics: Dictionary = {}

func last_response(person_id: String) -> String:
	return str(option(person_id, str(last_topics.get(person_id, ""))).get("response", ""))

func people_at(location_id: String, state: WorldState) -> Array[String]:
	var result: Array[String] = []
	for person_id: String in LOCATION_CAST.get(location_id, []):
		if _person_available(person_id, state):
			result.append(person_id)
	return result

func _person_available(person_id: String, state: WorldState) -> bool:
	if not state.characters.has(person_id):
		return false
	if person_id == "spouse":
		return str(state.facts.get("family_security", "")) not in ["country_cloister", "breached"]
	if person_id == "savva":
		return str(state.facts.get("savva_fate", "")) in ["protected_witness", "voluntary_witness"]
	if person_id == "vardan":
		return str(state.facts.get("vardan_stance", "")) == "inside_council"
	return true

func profile(person_id: String) -> Dictionary:
	return PROFILES.get(person_id, {})

func pending_story_topics(state: WorldState) -> Array[Dictionary]:
	var leads: Array[Dictionary] = []
	for location_id: String in LOCATION_CAST:
		for person_id: String in people_at(location_id, state):
			var city_case := _active_city_case(person_id, state)
			if not city_case.is_empty():
				leads.append({
					"location_id": location_id, "person_id": person_id, "option_id": "",
					"label": city_case["lead"], "city_case": city_case["fact"], "setup": city_case["setup"]
				})
			for option_id: String in available_options(person_id, state):
				var label := str(option(person_id, option_id).get("lead", ""))
				if not label.is_empty():
					leads.append({"location_id": location_id, "person_id": person_id, "option_id": option_id, "label": label})
	return leads

func city_case_brief(person_id: String, state: WorldState) -> String:
	return str(_active_city_case(person_id, state).get("setup", ""))

func _active_city_case(person_id: String, state: WorldState) -> Dictionary:
	var city_case: Dictionary = CITY_CASES.get(person_id, {})
	if city_case.is_empty() or state == null or state.calendar.is_demo_complete():
		return {}
	if state.calendar.cycle < int(city_case["start_cycle"]) or state.calendar.cycle > int(city_case["end_cycle"]):
		return {}
	if state.facts.has(str(city_case["fact"])) or not _meets_story_conditions(city_case, state):
		return {}
	return city_case

func available_options(person_id: String, state: WorldState = null) -> Array[String]:
	var result: Array[String] = []
	if state != null and not _person_available(person_id, state):
		return result
	var city_options: Dictionary = _active_city_case(person_id, state).get("options", {})
	for option_id: String in city_options:
		result.append(option_id)
	for option_id: String in (OPTIONS.get(person_id, {}) as Dictionary):
		if not bool(discussed.get("%s:%s" % [person_id, option_id], false)) and _meets_story_conditions(option(person_id, option_id), state):
			result.append(option_id)
	return result

func _meets_story_conditions(data: Dictionary, state: WorldState) -> bool:
	var required_facts: Dictionary = data.get("requires_facts", {})
	var required_event := str(data.get("requires_event", ""))
	var closing_event := str(data.get("closes_after", ""))
	if state == null:
		return required_facts.is_empty() and required_event.is_empty() and closing_event.is_empty()
	for key: String in required_facts:
		if state.facts.get(key) != required_facts[key]:
			return false
	var resolved := state.story_timeline.resolved
	if not required_event.is_empty():
		var record: Dictionary = resolved.get(required_event, {})
		if record.get("choice") not in data["requires_choices"]:
			return false
	return closing_event.is_empty() or not resolved.has(closing_event)

func option(person_id: String, option_id: String) -> Dictionary:
	var main_options: Dictionary = OPTIONS.get(person_id, {})
	if main_options.has(option_id):
		return main_options[option_id]
	var city_case: Dictionary = CITY_CASES.get(person_id, {})
	var city_options: Dictionary = city_case.get("options", {})
	return city_options.get(option_id, {})

func choose(state: WorldState, person_id: String, option_id: String) -> String:
	if not state.can_govern() or option_id not in available_options(person_id, state):
		return ""
	var data := option(person_id, option_id)
	if data.is_empty():
		return ""
	discussed["%s:%s" % [person_id, option_id]] = true
	last_topics[person_id] = option_id
	var person: CharacterState = state.characters[person_id]
	person.remember(state.calendar.cycle, "conversation_%s" % option_id, "Разговор: %s" % str(data["title"]), data.get("changes", {}))
	var new_facts: Dictionary = data.get("sets_facts", {})
	state.facts.merge(new_facts, true)
	if data.has("outcome"):
		_apply_city_case_choice(state, person_id, data)
	state.add_fatigue(1)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "character_conversation", "person": person_id, "option": option_id})
	return str(data["response"])

func _apply_city_case_choice(state: WorldState, person_id: String, data: Dictionary) -> void:
	var city_case: Dictionary = CITY_CASES[person_id]
	state.facts[str(city_case["fact"])] = data["outcome"]
	state.public_order = clampi(state.public_order + int(data.get("order_change", 0)), 0, 100)
	state.state_treasury += int(data.get("gold_change", 0))
	var faction_changes: Dictionary = data.get("faction_changes", {})
	for faction_id: String in faction_changes:
		var faction := state.factions[faction_id] as FactionState
		faction.react(state.calendar.cycle, int(faction_changes[faction_id]), str(data["reaction"]))

func to_data() -> Dictionary:
	return {"discussed": discussed.duplicate(true), "last_topics": last_topics.duplicate(true)}

func load_data(data: Dictionary) -> void:
	discussed = (data.get("discussed", {}) as Dictionary).duplicate(true)
	last_topics = (data.get("last_topics", {}) as Dictionary).duplicate(true)
