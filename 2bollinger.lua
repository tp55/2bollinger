-- Трендовая стратегия.
-- Два таймфрейма (глобальный и локальный). Например: H1 и M5.
-- Вход Лонг: цена выще MA20(H1), в момент пересечения противоположного Боллинджера (M5).
-- Шорт - наоборот.
-- Заточено под фьючи.
-- В комментариях ниже упоминается "старший Боллинлджер". Вместо него можно использовать MA,
-- потому что от старшего Боллинджера в этом алгоритме используется только средняя линия.

-- Сокращения ниже:
-- ВВ = боллинджер;
-- ЦПС = Цена Последней Сделки.

-- Настройка:
-- Открываем два графика торгуемого инструмента.
-- По умолчанию - H1 и М5.
-- Настраиваем идентификаторы на цену и индикаторы.
-- PREFIX+"_Price" - на цену на мледшем таймфрейме.
-- PREFIX+"_Global" - на MA СТАРШЕГО таймфрейма.
-- PREFIX+"_Local" - на Боллинджера на СТАРШЕМ таймфрейме.
-- Кстати, можно использовать один график М5, и наложить на него двух Боллинджеров.
-- Один будет с периодом 20, второй 120. Это примерно будет соответствовать двум графикам.
-- Включаем робота.
-- Ждем профита.

CLASS_CODE = "SPBFUT" -- или TQBR для акций
SEC_CODE = "SiM9" -- инструмент
PREFIX = "SiM9" -- префикс для получения данных с графиков. PREFIX+"_Price" - цена на младшем таймфрейме,
-- PREFIX+"_Global" и PREFIX+"_Local" - Старший и младший Боллинджер.
-- Префикс прописыватся на вкладке "Дополнительно" в графиках.
ACCOUNT_CODE = "сюда своё"
CLIENT_CODE = "сюда своё"
LogFileName = "C:\\Log\\trendovik_log.txt"
-- Не забывай использовать дфойной слеш в путях файла.

SL = "50" -- Стоп-лосс.
TP = "150" -- Включение трейлинга.
TRAIL = "150" -- кол-во пунктов отступа при трейлинге прибыли
-- TP=55, TRAIL=5, то есть коснется +55, значит уже как минимум 50 взято, скорее всего сразу закроет.
-- TP=55, TRAIL=50, то есть коснется +55, значит +5 наше, запас хода 50 пунктов, еще покачается.
LotN = "1" -- количство лотов.
SleepDuration = 10 -- СЕКУНД на паузу. По умолчанию ставлю 10 сек.
-- Робот не ждет закрытия свечи, а открывает сделку в момент пересечения. Точнее, не в момент,
-- а раз в SleepDuration/1000 секунд.
ContrTrendFlag = 0 -- если = 0, то сделка открывается в момент вылета за Боллинджера младшего таймфрейма.
-- А если = 1, то когда происходит вход внутрь канала Боллинджера на младшем таймфрейме.
JustMAFlag = 1 -- отменяет параметр ContrTrendFlag, и сделка открыватся на пересечении средней.
StartDayTime = "1015" -- раньше этого времени сделки не открываются.
EndDayTime = "1820" -- позже этого времени сделки тоже не открываются.

is_run=true

function DoFireWithTrail(p_price, p_dir)
	res1 = DoFire(p_price, p_dir);
	if (res1=="" or res1==nil) then -- если нормально открылись, то ставим стоп+трейл
		DoTrailStop(p_price, p_dir, TP, TRAIL, SL)
	end
end

function DoFire(p_price, p_dir) -- "B" or "S" -- СДЕЛКА ПО РЫНКУ!!!

	-- Сначала проверим время - можно ли входить.
	dt = os.date()
	d_hh = string.sub(dt, 10, 11)
	d_mm = string.sub(dt, 13, 14)
	d_hh_mm=d_hh..d_mm
	
	if (d_hh_mm<StartDayTime) or (d_hh_mm>EndDayTime) then
		WLOG(os.date().." No Time for Work.")
		return -1;
	end

	WLOG("DoFire. Start. p_dir="..p_dir..". p_price="..p_price)

	-- Здесь - три вспомогательных флага направления. Чтобы не писать отдельно для Лонг и Шорт.
	if p_dir == "B" then AAA = 1 else AAA = -1 end

	-- Готовим транзакцию для сделки.
	t = {
			["CLASSCODE"]=CLASS_CODE,
			["SECCODE"]=SEC_CODE,
			["ACTION"]="NEW_ORDER",
			["ACCOUNT"]=ACCOUNT_CODE,
			["CLIENT_CODE"]=CLIENT_CODE,
			["TYPE"]="M", -- или "L" если отложка.
			["OPERATION"]=p_dir,
			["QUANTITY"]=tostring(LotN),
			["PRICE"]=tostring(p_price+(20*AAA)),
			["TRANS_ID"]="1"
		}
		
	res1 = sendTransaction(t) -- передаем сделку по рынку.
	WLOG("Результат сделки по рынку (должно быть пусто) = '"..res1.."'")
	WLOG("DoFire. End.") -- Пишем в лог, что эту контрольную точку прошли.
	return res1
end

function DoTrailStop(p_price, p_dir, TP, TRAIL, SL) -- "B" or "S" -- СДЕЛКА ПО РЫНКУ!!!

	WLOG("DoTrailStop. Start. p_dir="..p_dir..". p_price="..p_price)

	-- Здесь - три вспомогательных флага направления. Чтобы не писать отдельно для Лонг и Шорт.
	if p_dir == "B" then AAA = 1 else AAA = -1 end
	if p_dir == "B" then BBB = "S" else BBB = "B" end
	if p_dir == "B" then CCC = "4" else CCC = "5" end

	t_stop =
	{
		['ACTION'] = "NEW_STOP_ORDER", 
		['PRICE'] = tostring(p_price-(100*AAA)), -- меньше, проскальзывание
		['EXPIRY_DATE'] = "GTC",
		['STOPPRICE'] = tostring(p_price+(TP*AAA)), -- тейк
		['STOPPRICE2'] = tostring(p_price-(SL*AAA)), -- больше, срабатывание стопа
		['STOP_ORDER_KIND'] = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER",
		['OFFSET'] = tostring(TRAIL),
		["OFFSET_UNITS"] = "PRICE_UNITS",
		["MARKET_TAKE_PROFIT"] = "YES",
		['TRANS_ID'] = "2",
		['CLASSCODE'] = CLASS_CODE,
		['SECCODE'] = SEC_CODE,
		['ACCOUNT'] = ACCOUNT_CODE,
		['CLIENT_CODE'] = CLIENT_CODE, 
		['TYPE'] = "L", -- лимитка
		['OPERATION'] = BBB, -- направление стопа (обратное к сделке).
		['CONDITION'] = tostring(CCC), -- 4 или 5 ("меньше или равно" или "больше или равно") - направление стоп-цены.
		['QUANTITY'] = tostring(LotN) -- кол-во контрактов
	}	
	res2 = sendTransaction(t_stop)
	WLOG("Результат выставления стопа (должно быть пусто) = '"..res2.."'")
   
	WLOG("DoTrailStop. End.") -- Пишем в лог, что эту контрольную точку прошли.
end

function main()
	while is_run do
		-- Выяснить, существует ли сейчас выставленная заявка или открытая сделка.
		-- Если Да, то ВЫХОД
		if HaveOpenPosition() then
			-- Если есть открытая позиция, то ничего не делаем, курим.
			-- И пишем об этом в лог.
			WLOG(os.date().." Have Open Position. Do nothing.")
		else
			-- Получить значение МА (BB-средней) час и 5 минут, открытие свечи и текущую цену.
			local NbbG=getNumCandles(PREFIX.."_Global")
			tbbG, nbbG, lbbG = getCandlesByIndex (PREFIX.."_Global", 0, NbbG-1, 1)  -- last свеча
			iBB_Global_Middle = tbbG[0].close -- тек значение средней BB_Global
			
			-- теперь собираем данные по младшему таймфрейму.
			local NbbL=getNumCandles(PREFIX.."_Local")
			tbbL, nbbL, lbbL = getCandlesByIndex (PREFIX.."_Local", 0, NbbL-1, 1)  -- last свеча, средняя линия Боллинджера
			iBB_Local_Middle = tbbL[0].close -- тек значение средней BB Local
			tbbL, nbbL, lbbL = getCandlesByIndex (PREFIX.."_Local", 1, NbbL-1, 1)  -- last свеча, верхняя линия Боллинджера
			iBB_Local_High = tbbL[0].close -- тек значение верхней BB Local
			tbbL, nbbL, lbbL = getCandlesByIndex (PREFIX.."_Local", 2, NbbL-1, 1)  -- last свеча, нижняя линия Боллинджера
			iBB_Local_Low = tbbL[0].close -- тек значение нижней BB Local

			local NL=getNumCandles(PREFIX.."_Price")
			tL, nL, lL = getCandlesByIndex (PREFIX.."_Price", 0, NL-1, 1) -- last свеча
			iLastPrice = tL[0].close -- получили текущую цену (ЦПС)
			iStartPrice = tL[0].open -- получили стартовую цену текущей свечи мледщего таймфрейма
			--iHighPrice = tL[0].high -- получили хай свечи
			--iLowPrice = tL[0].low -- получили лоу свечи
			WLOG(os.date().." BB_Global="..iBB_Global_Middle.." | BB_Local="..iBB_Local_Middle.." | Open_Local="..iStartPrice.." | LastPrice="..iLastPrice)
			
			-- Если (ЦПС > MA20H1) и пересекли Боллинджера внутрь снизу, то ЛОНГ
			if (JustMAFlag==1) then
				-- средняя включена. Сначала проверяем на Лонг.
				if (iLastPrice > iBB_Global_Middle) then
					if (iStartPrice < iBB_Local_Middle) and (iLastPrice > iBB_Local_Middle) then
						DoFireWithTrail(tostring(iLastPrice), "B");
					end
				end
				-- теперь на шорт.
				if (iLastPrice < iBB_Global_Middle) then
					if (iStartPrice > iBB_Local_Middle) and (iLastPrice < iBB_Local_Middle) then
						DoFireWithTrail(tostring(iLastPrice), "S");
					end
				end
			else
				-- Средняя отключена, так что бьем вылет или вход Боллинджера.
				if (iLastPrice > iBB_Global_Middle) then
					if (ContrTrendFlag==1) then -- вход внутрь Боллинджера младшего таймфрейма.
						-- пересечение произошло между началом свечи и текущей ценой.
						if (iStartPrice < iBB_Local_Low) and (iLastPrice > iBB_Local_Low) then
							DoFire(tostring(iLastPrice), "B");
						end
					end
					if (ContrTrendFlag==0) then -- вылет из локального Боллинджера.
						-- Пересечение произошло между лоу свечки и текущей ценой.
						if (iStartPrice < iBB_Local_High) and (iLastPrice > iBB_Local_High) then
							DoFire(tostring(iLastPrice), "B");
						end
					end
				end
				-- Если (наоборот) то ШОРТ
				if (iLastPrice < iBB_Global_Middle) then
					if (ContrTrendFlag==1) then -- вход внутрь Боллинджера младшего таймфрейма.
						-- пересечение произошло между началом свечи и текущей ценой.
						if (iStartPrice > iBB_Local_High) and (iLastPrice < iBB_Local_High) then
							DoFire(tostring(iLastPrice), "S");
						end
					end
					if (ContrTrendFlag==0) then -- пересечение лоу Боллинджера младшего таймфрейма.
						-- Пересечение произошло между ХАЙ свечки и текущей ценой.
						-- То есть свечка пробила нижнюю линию локального Боллинджера вниз.
						if (iStartPrice > iBB_Local_Low) and (iLastPrice < iBB_Local_Low) then
							DoFire(tostring(iLastPrice), "S");
						end
					end
				end
			end
		end
		
		sleep(SleepDuration*1000) -- Отдыхаем SleepDuration секунд.
	end
end

function OnStop(stop_flag)
	is_run=false
end

function HaveOpenPosition() -- Возвращает TRUE, если есть открытая позиция по инструменту.
	for i = 0,getNumberOf("FUTURES_CLIENT_HOLDING") - 1 do
		if getItem("FUTURES_CLIENT_HOLDING",i).sec_code == SEC_CODE then
			if getItem("FUTURES_CLIENT_HOLDING",i).totalnet ~= 0 then
				return true
			else
				return false
			end
		end
	end
end

function WLOG(p_st) -- Универсальная функция записи в лог.
	local l_file=io.open(LogFileName, "a")
	l_file:write(p_st.."\n")
	l_file:close()
end
