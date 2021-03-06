module DataStructures.HashTable.HashTableSChaining(
    HashTableSC(..),
    getTable,
    empty,
    isEmpty,
    put,
    getValue,
    replace,
    removeKey,
    putAll,
    hashSChaining,
    resize,
    entries,
    keys,
    values,
    containsKey,
    containsValue,
    getNumPairs,
    clear,
    size,
    printHT,
    helpHTS
) where

import Data.Array
import qualified Data.List as List
import Data.Hashable
import Data.Maybe


-- SEPARATE CHAINING:
-- Trata de evitar las colisiones entre elementos que se insertan a la tabla con
-- posibles valores para la función de hash iguales mediante el uso de listas enlazadas
-- asociadas a cada valor de la función de hash que utilizamos.

-----------------------
-- CONSTRUCTORES
-----------------------
-- Lo implemenntamos mediante un array que contendrá para cada indice del mismo
-- una lista enlazada con los pares que se inserten y tengan como valor de hash
-- el índice del array.
-- Llamaermos a cada una de estas listas enlazadas buckets.
-- Igualmente guardaremos el número de pares contenidos en la tabla con el fin 
-- de hacer más eficientes los cálculos asociados al aumento/disminución del
-- tamaño de la tabla.
--
--        HashTableSC = |pares contenidos| [indice bucket, [pares en el bucket]]
--
data HashTableSC a b = HashTableSC Int (Array Int [(a, b)])
  deriving (Show, Eq)


-----------------------
-- FUNCIONES
-----------------------

helpHTS :: IO ()
helpHTS = putStrLn "\ngetTable :: HashTableSC a b -> Array Int [(a,b)]\n\nempty :: Int -> HashTableSC a b\n\nisEmpty :: (Eq a, Eq b) => HashTableSC a b -> Bool\n\nput :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTableSC a b -> HashTableSC a b\n\ngetValue :: (Hashable k, Eq k) => k -> HashTableSC k v -> Maybe (k, v)\n\nreplace :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTableSC a b -> HashTableSC a b\n\nremoveKey :: (Hashable a, Eq a, Eq b) => a -> HashTableSC a b -> HashTableSC a b\n\nputAll :: (Hashable a, Eq a, Eq b) => HashTableSC a b -> HashTableSC a b -> HashTableSC a b\n\nhashSChaining :: Hashable a => Int -> a -> Int\n\nresize :: (Hashable a, Eq a, Eq b) => Int -> HashTableSC a b -> HashTableSC a b\n\nentries :: HashTableSC a b -> [(a,b)]\n\nkeys :: HashTableSC a b -> [a]\n\nvalues :: HashTableSC a b -> [b]\n\ncontainsKey :: (Hashable a, Eq a) => a -> HashTableSC a b-> Bool\n\ngetNumPairs :: HashTableSC a b -> Int\n\nclear :: Eq a => HashTableSC a b -> HashTableSC a b\n\nsize :: HashTableSC a b -> Int\n\nprintHT :: (Show a, Show b) => HashTableSC a b -> String"

getTable :: HashTableSC a b -> Array Int [(a,b)]
getTable (HashTableSC _ table) = table

empty :: Int -> HashTableSC a b
empty n = HashTableSC 0 (array (0, n-1) [(i,[]) | i <- [0..n-1]])

isEmpty :: (Eq a, Eq b) => HashTableSC a b -> Bool
isEmpty t@(HashTableSC _ table) = t == empty (length table)


put :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTableSC a b -> HashTableSC a b
-- Inserta el par (a, b) en la tabla.
-- Parámetros: Par clave-valor
--             Tabla en la que se inserta
-- Devuelve:   Tabla con el par insertado

-- Se encarga de hacer un aumento/disminución de la tabla y posteriormente realiza la inserción.
put (k, v) t@(HashTableSC pairs table) = if (fromIntegral pairs) >= ((fromIntegral buckets) / 2) 
                                     then let resized = resize (2*buckets) t 
                                          in put' (k,v) resized 
                                     else put' (k, v) t
    where buckets = length table

-- Inserta el par en la tabla
put' (k, v) t@(HashTableSC pairs table) = 
  if containsKey k t                                                          -- Comprobamos si la tabla ya contiene el par y lo reemplazamos si es así
  then let removedKey = getTable (removeKey k t)                              --    Eliminamos el par en la tabla
        in (HashTableSC pairs (removedKey // [(i, (k,v) : (removedKey ! i))]))
  else (HashTableSC (pairs+1) (table // [(i, (k,v) : (table ! i))]))            -- En otro caso, insertamos el par en el array de la tabla
  where i = hashSChaining (List.length table) k
        -- índice del bucket en el que se inserta el par

getValue :: (Hashable k, Eq k) => k -> HashTableSC k v -> Maybe (k, v)
-- Obtiene el valor asociado a la clave que recibe en la tabla correspondiente.
-- Parámetros: Clave de la que queremos obtener el valor.
--             Tabla de la que lo obtenemos.
-- Devuelve:   Par clave-valor
getValue key (HashTableSC _ table) = List.find (\(k,v) -> k == key) bucket    -- Buscamos en el bucket un par con clave igual a la buscada
  where position = hashSChaining (List.length table) key                   -- si no se enceuntra, devuelve Nothing.
        bucket = table ! position

replace :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTableSC a b -> HashTableSC a b
replace (k, v) t = put (k, v) t

removeKey :: (Hashable a, Eq a, Eq b) => a -> HashTableSC a b -> HashTableSC a b
-- Elimina el par asociado a la clave en la tabla.
-- Parámetros: Clave.
--             Tabla.
-- Devuevle:   Tabla con el par eliminado.

-- Se encarga de hacer un aumento/disminución de la tabla tras la eliminación del par
removeKey key t@(HashTableSC _ table) = if pairs > 0 && (fromIntegral pairs) <= (fromIntegral buckets / 8) then resize (div buckets 2) removed else removed
    where removed = removeKey' key t
          pairs = getNumPairs removed
          buckets = length (getTable removed)

-- Elimina el par de la tabla si este existe
removeKey' key t@(HashTableSC pairs table) = 
  case getValue key t of
    Nothing -> t
    Just (k,v) -> (HashTableSC (pairs-1) (table // [(i, newxs)]))
      where i = hashSChaining (List.length table) key
            xs = table ! i
            newxs = List.delete (k,v) xs

putAll :: (Hashable a, Eq a, Eq b) => HashTableSC a b -> HashTableSC a b -> HashTableSC a b
-- Inserta todos los pares de la segunda tabla recibida en la primera
-- Parámetros: Tabla 1
--             Tabla 2
-- Devuelve:   Tabla 1 con los nuevos pares
putAll t1 t2 = foldr (\(k,v) ac -> put (k,v) ac) t1 entrySet
    where entrySet = entries t2

hashSChaining :: Hashable a => Int -> a -> Int
-- Calcula la función de hash a partir de n (longitud de la tabla)
hashSChaining n v = mod (hash v) n

resize :: (Hashable a, Eq a, Eq b) => Int -> HashTableSC a b -> HashTableSC a b
-- Cambia el tamaño de la tabla insertando todos los elementos en una vacía con la capacidad indicada
resize capacity t = putAll (empty capacity) t

entries :: HashTableSC a b -> [(a,b)]
entries (HashTableSC _ table) = concat [table!i | i<-[0..n-1]]
    where n = length table

keys :: HashTableSC a b -> [a]
keys (HashTableSC _ table) = concat [map fst entries | i<-[1..(length table)-1], let entries = table!i]
    where n = length table

values :: HashTableSC a b -> [b]
values (HashTableSC _ table) = concat [map snd entries | i<-[1..(length table)-1], let entries = table!i]
    where n = length table

containsKey :: (Hashable a, Eq a) => a -> HashTableSC a b-> Bool
containsKey k t@(HashTableSC _ table) = if isNothing (getValue k t) then False else True

containsValue :: Eq b => b -> HashTableSC a b -> Bool
containsValue v t = any (==v) (values t)

getNumPairs :: HashTableSC a b -> Int
getNumPairs (HashTableSC pairs table) = pairs
    
clear :: HashTableSC a b -> HashTableSC a b
clear t@(HashTableSC _ table) = empty (length table)

size :: HashTableSC a b -> Int
size t@(HashTableSC _ table) = length table


printHT :: (Show a, Show b) => HashTableSC a b -> String
printHT t@(HashTableSC pairs table) = linea ++ header ++ linea ++ contenido ++ linea
    where n = length table
          width = 90
          linea = (concat ["-" | i<-[0..width]]) ++ "\n"
          header = "| Bucket    | Entries (key-value pairs)                                                   |\n"
          leftPad = 11
          rightPad = 77
          contenido = concat ["| " ++ (show i) ++ (concat [" " | j<-[0..difLeft-1]]) ++ "| " ++ (procesaEntradas (show (table!i))) ++ " |\n" 
            | i<-[0..n-1], let difLeft = leftPad - (length (show i))-1]
          procesaEntradas cadena | nc > rightPad = (take (rightPad-2) cadena) ++ " |\n" ++ "|           | " ++ (procesaEntradas ((drop rightPad cadena) ++ (concat [" " | j<-[0..(rightPad - length (drop 36 cadena))]])))
                                 | otherwise = cadena ++ (concat [" " | j<-[0..difRight-3]])
                                 where nc = length cadena
                                       difRight = rightPad - nc

-- Ejemplos

t1 :: HashTableSC String [Int]
t1 = HashTableSC 1 (array (0,9) [(0,[]),(1,[]),(2,[]),(3,[]),(4,[]),(5,[]),(6,[]),(7,[("Paco",[1,2])]),(8,[]),(9,[])])
-- test doubling size by inserting pair
t2, t3 :: HashTableSC Int Int
t2 = HashTableSC 3 (array (0,5) [(0,[(1,0)]),(1,[(2,0)]),(2,[(3,0)]),(3,[]),(4,[]),(5,[])])
-- test halving sive by removing pair
t3 = HashTableSC 1 (array (0,9) [(0,[(1,0)]),(1,[]),(2,[]),(3,[]),(4,[]),(5,[]),(6,[]),(7,[]),(8,[]),(9,[])])
t4 :: HashTableSC String String
t4 = HashTableSC 4 (array (0,9) [(0,[("Juan","Benitez")]),(1,[("Pedro","Almagro")]),(2,[]),(3,[("Tomas","Galera")]),(4,[]),(5,[("Antonio","Losada")]),(6,[]),(7,[]),(8,[]),(9,[])])