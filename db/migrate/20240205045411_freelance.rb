class Freelance < ActiveRecord::Migration[7.0]
  def change
    create_table :freelancers do |t|
      t.string :login
      t.string :password
      t.integer :complete_count, default: 0
      t.timestamps
    end

    create_table :channel_themes do |t|
      t.string :title
    end

    [[1, "Авто и мото"],
     [31, "Авторские блоги"],
     [45, "Арабские"],
     [3, "Бизнес и стартапы"],
     [11, "Видеоигры"],
     [61, "В мире животных"],
     [39, "Дети и родители"],
     [38, "Дом и уют"],
     [28, "Другое"],
     [23, "Еда и кулинария"],
     [13, "Женский раздел"],
     [7, "Здоровье и медицина"],
     [51, "Знаменитости и образ жизни"],
     [60, "Инвестиции"],
     [44, "Индия"],
     [20, "Иностранные языки"],
     [32, "Интернет технологии"],
     [43, "Искусство и дизайн"],
     [56, "История"],
     [26, "Каталоги каналов и ботов"],
     [27, "Кино"],
     [42, "Книги, Аудиокниги и Подкасты"],
     [36, "Красота и уход"],
     [29, "Криптовалюты"],
     [52, "Культура и события"],
     [53, "Любопытные факты"],
     [8, "Маркетинг и PR"],
     [37, "Мода и стиль"],
     [24, "Мотивация и саморазвитие"],
     [25, "Музыка"],
     [18, "Наука и технологии"],
     [6, "Недвижимость"],
     [17, "Новости и СМИ"],
     [16, "Образование"],
     [15, "Отдых и развлечения"],
     [4, "Офис"],
     [62, "Политика"],
     [63, "Психология и отношения"],
     [12, "Путешествия и туризм"],
     [10, "Работа и вакансии"],
     [40, "Региональные"],
     [64, "Религия и духовность"],
     [19, "Скидки и акции"],
     [41, "Сливы Заработок"],
     [14, "Спорт"],
     [49, "Ставки и азартные игры"],
     [58, "Строительство и ремонт"],
     [46, "США"],
     [65, "Трейдинг"],
     [30, "Удалёнка и фриланс"],
     [35, "Узбекские каналы"],
     [55, "Фитнес"],
     [57, "Хобби и развлечения"],
     [54, "Экономика и Финансы"],
     [47, "Эфиопия"],
     [59, "Юмор и мемы"],
     [34, "Юриспруденция"],
     [21, "18+"]].each do |i|
      ChannelTheme.create(id: i[0], title: i[1])
    end

    create_table :freelancer_theme_ties do |t|
      t.integer :freelancer_id
      t.integer :channel_theme_id
    end

  end
end
