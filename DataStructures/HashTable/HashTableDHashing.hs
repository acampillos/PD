import Data.Array (array, Array, (//), (!))
import qualified Data.List as List (find, length, delete)
import Data.Hashable
import Data.Maybe
import Data.Numbers.Primes

--  Tipos de hashing comunes
--      Separate chaining       
--      Open adressing          
--          Linear probing      
--          Quadratic probing   
--          Double hashing      <


--                           |pares|, tabla
data HashTable a b = HashTable Int (Array Int [(a, b)])
  deriving (Show, Eq)

getTable :: HashTable a b -> Array Int [(a,b)]
getTable (HashTable _ arr) = arr

empty :: Eq a => Int -> HashTable a b
empty n = HashTable 0 (array (0, n-1) [(i,[]) | i <- [0..n-1]])

isEmpty :: (Eq a, Eq b) => HashTable a b -> Bool
isEmpty t@(HashTable _ arr) = t == empty (length arr)

put :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTable a b -> HashTable a b
put (k, v) t@(HashTable pairs arr) = if pairs >= (div buckets 2) 
                                     then let resized = resize (2*buckets) t 
                                          in put' (k,v) resized 
                                     else put' (k, v) t
    where buckets = length arr

put' (k, v) t@(HashTable pairs arr) = if containsKey k t
                                    then let removedKey = getTable (removeKey k t)
                                         in (HashTable pairs (removedKey // [(i, (k,v) : (removedKey ! i))])) 
                                    else (HashTable (pairs+1) (arr // [(i, (k,v) : (arr ! i))]))
  where i = hashDHashing t k 
        

entries :: HashTable a b -> [(a,b)]
entries (HashTable _ arr) = concat [arr!i | i<-[0..n-1]]
    where n = length arr

keys :: HashTable a b -> [a]
keys (HashTable _ arr) = concat [map fst entries | i<-[1..(length arr)-1], let entries = arr!i]
    where n = length arr

values :: HashTable a b -> [b]
values (HashTable _ arr) = concat [map snd entries | i<-[1..(length arr)-1], let entries = arr!i]
    where n = length arr

containsKey :: (Hashable a, Eq a) => a -> HashTable a b-> Bool
containsKey k t@(HashTable _ arr) = if isNothing (getValue k t) then False else True

containsValue :: Eq b => b -> HashTable a b -> Bool
containsValue v t = any (==v) (values t)
    
getValue :: (Hashable k, Eq k) => k -> HashTable k v -> Maybe (k, v)
getValue key t@(HashTable _ table) = if null result then Nothing else head result
  where position = hashDHashing t key
        result = filter (not . isNothing) 
          (map (List.find (\(k,v) -> k == key)) 
            ([bucket | i<-[position..(length table)-1], let bucket = table!i] ++ [bucket | i<-[0..position-1], let bucket = table!i]))

clear :: Eq a => HashTable a b -> HashTable a b
clear t@(HashTable _ arr) = empty (length arr)

size :: HashTable a b -> Int
size t@(HashTable _ arr) = length arr

-- merge?

replace :: (Hashable a, Eq a, Eq b) => (a, b) -> HashTable a b -> HashTable a b
replace (k, v) t = put (k, v) t

removeKey :: (Hashable a, Eq a, Eq b) => a -> HashTable a b -> HashTable a b
removeKey key t@(HashTable pairs table) = 
  case getValue key t of
    Nothing -> t
    Just (k,v) -> HashTable (pairs-1) (table // [(position', bucket')])
      where position = hashSChaining (List.length table) key
            buckets = [(i,bucket) | i<-[position..(length table)-1], let bucket = table!i] ++ [(i,bucket) | i<-[0..position-1], let bucket = table!i]
            indexedBucket = filter (\(i,xs) -> any (\(ke, val) -> ke==key) xs) buckets
            position' = fst (head indexedBucket)
            bucket = table ! position'
            bucket' = List.delete (k,v) bucket

hashSChaining :: Hashable a => Int -> a -> Int
hashSChaining n = (`mod` n) . hash

--  Revisar: Problema con los numeros aleatorios para coseguir un primo aleatorio menor que el tamaño de la tabla
hash' :: Hashable a => Int -> a -> Int
hash' n v = prime - (mod v' prime)
    where primes = wheelSieve 6
          v' = hash v
          prime = snd (minimum [(abs(v'-p), p) | p<-primes, p<n])

--                              tabla          v    posicion en la tabla
hashDHashing :: Hashable a => HashTable a b -> a -> Int
hashDHashing t@(HashTable _ arr) v
    | null (arr ! i) = i
    | otherwise = fst (head (filter (\(_, b) -> null b) ([(j',arr!j') | j<-[(i+1*1),(i+2*2)..n-1], let j' = mod j n])))
    where n = length arr
          i = hashSChaining n v
          h2 = hash' n v

--  From Linear Probing:
--      No se si la parte concatenada es necesaria en este metodo
--    | otherwise = fst (head (filter (\(_, b) -> null b) ([(j,arr!j) | j<-[i..n-1]] ++ [(j,arr!j) | j<-[0..i]])))


--  newSize, oldHT, (numKeys, numValues) {no se si lo puedo sacar por dentro y ya}
resize :: (Hashable a, Eq a, Eq b) => Int -> HashTable a b -> HashTable a b
resize capacity t = putAll (empty capacity) t

putAll :: (Hashable a, Eq a, Eq b) => HashTable a b -> HashTable a b -> HashTable a b
putAll t1 t2 = foldr (\(k,v) ac -> put (k,v) ac) t1 entrySet
    where entrySet = entries t2

t1 :: HashTable String [Int]
t1 = HashTable 1 (array (0,9) [(0,[]),(1,[]),(2,[]),(3,[]),(4,[]),(5,[]),(6,[]),(7,[("Paco",[1,2])]),(8,[]),(9,[])])
-- test doubling size by inserting pair
t2 :: HashTable Int Int
t2 = HashTable 3 (array (0,5) [(0,[(1,0)]),(1,[(2,0)]),(2,[(3,0)]),(3,[]),(4,[]),(5,[])])
-- test halving sive by removing pair
t3 :: HashTable Int Int
t3 = HashTable 1 (array (0,9) [(0,[(1,0)]),(1,[]),(2,[]),(3,[]),(4,[]),(5,[]),(6,[]),(7,[]),(8,[]),(9,[])])