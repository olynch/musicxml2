
{-# LANGUAGE ScopedTypeVariables, NoMonomorphismRestriction #-}

-------------------------------------------------------------------------------------
-- |
-- Copyright   : (c) Hans Hoglund 2012
--
-- License     : BSD-style
--
-- Maintainer  : hans@hanshoglund.se
-- Stability   : experimental
-- Portability : portable
--
-- Provides smart(er) constructors for the MusicXML representation.
--

-------------------------------------------------------------------------------------

module Music.MusicXml.Simple (

        (&),
        (&!),
    
        -----------------------------------------------------------------------------
        -- * Score and parts
        -----------------------------------------------------------------------------

        -- ** Basic constructors
        partList,
        partListAbbr,
        partwise,

        -- -- ** Others
        -- partIds,
        -- header,
        -- setHeader,
        -- setTitle,
        -- setMvmTitle,
        -- parts, 

        -----------------------------------------------------------------------------
        -- * Top-level attributes
        -----------------------------------------------------------------------------

        -- ** Pitch
        -- *** Clef
        trebleClef,
        altoClef,
        bassClef, 
        
        -- *** Key signature
        key,

        -- ** Time
        -- *** Divisions
        stdDivs,        
        -- *** Time signature
        commonTime,
        cutTime,
        time,

        -- *** Tempo
        -- TODO tempo
        metronome,
        
        -----------------------------------------------------------------------------
        -- * Notes
        -----------------------------------------------------------------------------
        
        -- ** Basic constructors
        rest,
        note,
        chord,

        -- ** Voice
        setVoice,

        -- ** Duration
        dot,
        setNoteVal,
        setTimeMod,

        -- ** Ties and beams
        beginTie,
        endTie,

        beam,
        beginBeam,
        continueBeam,
        endBeam,

        -- ** Tuplets
        tuplet,
        beginTuplet,
        endTuplet,

        -- ** Notations
        addNotation,

        -----------------------------------------------------------------------------
        -- * Text
        -----------------------------------------------------------------------------

        rehearsal,
        segno,
        text,

        -----------------------------------------------------------------------------
        -- * Glissando etc
        -----------------------------------------------------------------------------

        beginGliss,
        endGliss,
        beginSlide,
        endSlide,
        fermata,
        caesura,


        -----------------------------------------------------------------------------
        -- * Articulation
        -----------------------------------------------------------------------------

        beginSlur,
        endSlur,
        staccato,
        tenuto,

        accent,
        strongAccent,
        detachedLegato,
        staccatissimo,
        spiccato,
        scoop,
        plop,
        doit,
        falloff,
        breathMark,
        stress,
        unstress,

        -----------------------------------------------------------------------------
        -- * Dynamics
        -----------------------------------------------------------------------------

        -- ** Crescendo and diminuendo
        beginCresc,
        endCresc,
        beginDim,
        endDim,

        -- ** Dynamic levels
        pppppp,
        ppppp,
        pppp,
        ppp,
        pp,
        p,
        mp,
        mf,
        ff,
        fff,
        ffff,
        fffff,
        ffffff,
  ) 
where

import Data.Default
import Data.Ratio
import Control.Apply.Reverse

import Music.MusicXml.Score
import Music.MusicXml.Time
import Music.MusicXml.Pitch
import Music.MusicXml.Dynamics
import Music.MusicXml.Read
import Music.MusicXml.Write

instance Default ScoreAttrs where
    def = ScoreAttrs []

instance Default ScoreHeader where
    def = ScoreHeader Nothing Nothing Nothing []

instance Default Note where
    def = Note def def [] def

instance Default Divs where
    def = stdDivsVal

instance Default FullNote where
    def = Rest noChord Nothing

instance Default NoteProps where
    def = NoteProps Nothing Nothing (Just (1/4, Nothing)) 0 Nothing Nothing Nothing Nothing Nothing Nothing Nothing [] []


-- class HasDyn a where
--     mapLevel :: (Level -> Level) -> (a -> a)
-- 
-- class HasPitch a where
--     mapPitch :: (Pitch -> Pitch) -> (a -> a)
-- 
-- class HasPitch a => HasAcc a where
--     flatten :: a -> a
--     sharpen :: a -> a
--     mapAcc  :: (Semitones -> Semitones) -> a -> a
--     flatten = mapAcc pred
--     sharpen = mapAcc succ





stdDivsVal :: Divs
stdDivsVal = 768*4

stdDivs :: Music
stdDivs = single $ MusicAttributes $ Divisions $ stdDivsVal `div` 4

trebleClef, altoClef, bassClef :: Music

trebleClef = single $ MusicAttributes $ Clef GClef 2
altoClef   = single $ MusicAttributes $ Clef CClef 3
bassClef   = single $ MusicAttributes $ Clef FClef 4

commonTime, cutTime  :: Music
time       :: Beat -> BeatType -> Music
key        :: Fifths -> Mode -> Music

commonTime = single $ MusicAttributes $ Time CommonTime
cutTime    = single $ MusicAttributes $ Time CutTime
time a b   = single $ MusicAttributes $ Time $ DivTime a b
key n m    = single $ MusicAttributes $ Key n m


partIds :: [String]
partIds = [ "P" ++ show n | n <- [1..] ]

partList :: [String] -> PartList
partList = zipWith (\partId name -> Part partId name Nothing) partIds

partListAbbr :: [(String, String)] -> PartList
partListAbbr = zipWith (\partId (name,abbr) -> Part partId name (Just abbr)) partIds



header :: String -> String -> PartList -> ScoreHeader
header title composer partList = ScoreHeader Nothing (Just title) (Just (Identification [Creator "composer" composer])) partList

setHeader header (Partwise attrs _ music) = Partwise attrs header music
setHeader header (Timewise attrs _ music) = Timewise attrs header music

setTitle    title    (ScoreHeader _ mvmTitle ident partList) = ScoreHeader title mvmTitle ident partList
setMvmTitle mvmTitle (ScoreHeader title _ ident partList) = ScoreHeader title (Just mvmTitle) ident partList
-- addIdent    ident    (ScoreHeader title mvmTitle idents partList) = ScoreHeader title mvmTitle (ident:idents) partList

parts :: [[Music]] -> [(PartAttrs, [(MeasureAttrs, Music)])]
parts = zipWith (\ids mus -> (PartAttrs ids, zipWith (\ids mus -> (MeasureAttrs ids, mus)) barIds mus)) partIds'
    where
        partIds' = partIds
        barIds   = [1..]



partwise :: String -> String -> PartList -> [[Music]] -> Score
partwise title comp partList music 
    = Partwise 
        (def)
        (header title comp partList)
        (parts music)  





setVoice     :: Int -> Music -> Music
setNoteVal     :: NoteVal -> Music -> Music
dot       :: Music -> Music
setTimeMod   :: Int -> Int -> Music -> Music
addNotation  :: Notation -> Music -> Music
beginBeam    :: Int -> Music -> Music
continueBeam :: Int -> Music -> Music
endBeam      :: Int -> Music -> Music

setNoteVal x    = fmap $ mapNoteProps2 (setNoteValP x)
setVoice n      = fmap $ mapNoteProps2 (setVoiceP n)
dot             = fmap $ mapNoteProps2 dotP
setTimeMod m n  = fmap $ mapNoteProps2 (setTimeModP m n)
addNotation x   = fmap $ mapNoteProps2 (addNotationP x)
beginBeam n     = fmap $ mapNoteProps2 (beginBeamP n)
continueBeam n  = fmap $ mapNoteProps2 (continueBeamP n)
endBeam n       = fmap $ mapNoteProps2 (endBeamP n)

beginTie' = fmap beginTie''
endTie'   = fmap endTie''
beginTie'' (MusicNote (Note full dur ties props)) = (MusicNote (Note full dur (ties++[Start]) props))
endTie''   (MusicNote (Note full dur ties props)) = (MusicNote (Note full dur ([Stop]++ties) props))

setNoteValP v x       = x { noteType = Just (v, Nothing) }
setVoiceP n x       = x { noteVoice = Just (fromIntegral n) }
dotP x@(NoteProps { noteDots = n@_ })    = x { noteDots = succ n }
setTimeModP m n x   = x { noteTimeMod = Just (fromIntegral m, fromIntegral n) }
addNotationP n x@(NoteProps { noteNotations = ns@_ })    = x { noteNotations = n:ns }
beginBeamP n x      = x { noteBeam = Just (fromIntegral n, BeginBeam) }
continueBeamP n x   = x { noteBeam = Just (fromIntegral n, ContinueBeam) }
endBeamP n x        = x { noteBeam = Just (fromIntegral n, EndBeam) }



-- TODO handle dots etc
rest :: NoteVal -> Music
rest dur = single $ MusicNote (Note def (stdDivsVal `div` denom) noTies (setNoteValP val def))
    where
        num   = fromIntegral $ numerator   $ toRational $ dur
        denom = fromIntegral $ denominator $ toRational $ dur
        val   = NoteVal $ toRational $ dur              

    

note :: Pitch -> NoteVal -> Music
note pitch dur = note' False pitch dur' dots
    where
        (dur', dots) = separateDots dur

chordNote :: Pitch -> NoteVal -> Music
chordNote pitch dur = note' True pitch dur' dots
    where
        (dur', dots) = separateDots dur

note' :: Bool -> Pitch -> NoteVal -> Int -> Music
note' isChord pitch dur dots 
    = single $ MusicNote $ 
        Note 
            (Pitched isChord $ pitch) 
            (stdDivsVal `div` denom) 
            noTies 
            (setNoteValP val $ addDots $ def)
    where                    
        addDots = foldl (.) id (replicate dots dotP)
        num     = fromIntegral $ numerator   $ toRational $ dur
        denom   = fromIntegral $ denominator $ toRational $ dur
        val     = NoteVal $ toRational $ dur              

separateDots :: NoteVal -> (NoteVal, Int)
separateDots = separateDots' [2/3, 6/7, 14/15, 30/31, 62/63]

separateDots' :: [NoteVal] -> NoteVal -> (NoteVal, Int)
separateDots' []         nv                    = error "Note value must be a multiple of two or dotted"
separateDots' (div:divs) nv | divisibleBy 2 nv = (nv,  0)
                            | otherwise        = (nv', dots' + 1)
    where                            
        (nv', dots') = separateDots' divs (nv*div)
        divisibleBy n = (== 0.0) . snd . properFraction . logBaseRational n . toRational

    
chord :: [Pitch] -> NoteVal -> Music
chord [] d      = rest d
chord (p:ps) d  = note p d ++ concatMap (\p -> chordNote p d) ps




rehearsal :: String -> Music
segno :: Music
text :: String -> Music
metronome :: NoteVal -> Bool -> Tempo -> Music

rehearsal = single . MusicDirection . Rehearsal
segno     = single . MusicDirection $ Segno
text      = single . MusicDirection . Words
metronome nv dot tempo = single $ MusicDirection (Metronome nv dot tempo)


beginTie    :: Music -> Music
endTie      :: Music -> Music
beginSlur   :: Music -> Music
endSlur     :: Music -> Music
beginTuplet :: Music -> Music
endTuplet   :: Music -> Music

staccato    :: Music -> Music
tenuto      :: Music -> Music

beginTie        = beginTie' . addNotation (Tied Start)
endTie          = endTie' . addNotation (Tied Stop)
beginSlur       = addNotation (Slur 1 Start)
endSlur         = addNotation (Slur 1 Stop)
beginTuplet     = addNotation (Tuplet 1 Start)
endTuplet       = addNotation (Tuplet 1 Stop)
beginGliss      = addNotation (Glissando 1 Start Solid Nothing)
endGliss        = addNotation (Glissando 1 Stop Solid Nothing)
beginSlide      = addNotation (Slide 1 Start Solid Nothing)
endSlide        = addNotation (Slide 1 Stop Solid Nothing)

fermata         = addNotation . Fermata

accent          = addNotation (Articulations [Accent])	 
strongAccent    = addNotation (Articulations [StrongAccent])	 
staccato        = addNotation (Articulations [Staccato])	 
tenuto          = addNotation (Articulations [Tenuto])	 
detachedLegato  = addNotation (Articulations [DetachedLegato])	 
staccatissimo   = addNotation (Articulations [Staccatissimo])	 
spiccato        = addNotation (Articulations [Spiccato])	 
scoop           = addNotation (Articulations [Scoop])	 
plop            = addNotation (Articulations [Plop])	 
doit            = addNotation (Articulations [Doit])	 
falloff         = addNotation (Articulations [Falloff])	 
breathMark      = addNotation (Articulations [BreathMark])	 
caesura         = addNotation (Articulations [Caesura])	 
stress          = addNotation (Articulations [Stress])	 
unstress        = addNotation (Articulations [Unstress])	 

beginCresc      = [MusicDirection $ Crescendo Start]
endCresc        = [MusicDirection $ Crescendo Stop]
beginDim        = [MusicDirection $ Diminuendo Start]
endDim          = [MusicDirection $ Diminuendo Stop]


beginCresc      :: Music
endCresc        :: Music
beginDim        :: Music
endDim          :: Music

pppppp      :: Music
ppppp       :: Music
pppp        :: Music
ppp         :: Music
pp          :: Music
p           :: Music
mp          :: Music
mf          :: Music
ff          :: Music
fff         :: Music
ffff        :: Music
fffff       :: Music
ffffff      :: Music

pppppp          = [MusicDirection $ Dynamics PPPPPP]
ppppp           = [MusicDirection $ Dynamics PPPPP]
pppp            = [MusicDirection $ Dynamics PPPP]
ppp             = [MusicDirection $ Dynamics PPP]
pp              = [MusicDirection $ Dynamics PP]
p               = [MusicDirection $ Dynamics P]
mp              = [MusicDirection $ Dynamics MP]
mf              = [MusicDirection $ Dynamics MF]
-- f               = [MusicDirection $ Dynamics F]
ff              = [MusicDirection $ Dynamics FF]
fff             = [MusicDirection $ Dynamics FFF]
ffff            = [MusicDirection $ Dynamics FFFF]
fffff           = [MusicDirection $ Dynamics FFFFF]
ffffff          = [MusicDirection $ Dynamics FFFFFF]


tuplet :: Int -> Int -> [Music] -> Music
tuplet m n []   = []
tuplet m n [xs] = xs
tuplet m n xs   = setTimeMod m n $ concat ([a] ++ bs ++ [c])
    where
        a   = beginTuplet $ head xs
        bs  = init (tail xs)
        c   = endTuplet $ last (tail xs)

beam :: [Music] -> Music
beam []   = []
beam [xs] = xs
beam xs   = concat ([a] ++ bs ++ [c])
    where
        a   = beginBeam 1 $ head xs
        bs  = fmap (continueBeam 1) (init (tail xs))
        c   = endBeam 1 $ last (tail xs)
                                           
-- TODO combine tuplet, beam, slur etc






logBaseRational :: forall a . (RealFloat a, Floating a) => Rational -> Rational -> a
logBaseRational k n 
    | isInfinite (fromRational n :: a)      = logBaseRational k (n/k) + 1
logBaseRational k n 
    | isDenormalized (fromRational n :: a)  = logBaseRational k (n*k) - 1
logBaseRational k n                         = logBase (fromRational k) (fromRational n)

single x = [x]