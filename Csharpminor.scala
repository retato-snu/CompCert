import io.circe._
import io.circe.generic.semiauto._

object Csharpminor {

  // --- Constants ---
  sealed trait Constant
  case class Ointconst(value: Long) extends Constant
  case class Ofloatconst(value: Double) extends Constant
  case class Osingleconst(value: Double) extends Constant
  case class Olongconst(value: Long) extends Constant

  implicit val constantDecoder: Decoder[Constant] = Decoder.instance { cursor =>
    cursor.downField("const_type").as[String].flatMap {
      case "int"    => cursor.downField("value").as[Long].map(Ointconst)
      case "float"  => cursor.downField("value").as[Double].map(Ofloatconst)
      case "single" => cursor.downField("value").as[Double].map(Osingleconst)
      case "long"   => cursor.downField("value").as[Long].map(Olongconst)
      case other    => Left(DecodingFailure(s"Unknown const type: $other", cursor.history))
    }
  }

  // --- Expressions ---
  sealed trait Expr
  case class Evar(id: String) extends Expr
  case class Eaddrof(id: String) extends Expr
  case class Econst(const: Constant) extends Expr
  case class Eunop(op: String, arg: Expr) extends Expr
  case class Ebinop(op: String, arg1: Expr, arg2: Expr) extends Expr
  case class Eload(chunk: String, addr: Expr) extends Expr

  implicit val exprDecoder: Decoder[Expr] = Decoder.instance { cursor =>
    cursor.downField("expr_type").as[String].flatMap {
      case "Evar"    => cursor.downField("id").as[String].map(Evar)
      case "Eaddrof" => cursor.downField("id").as[String].map(Eaddrof)
      case "Econst"  => cursor.downField("const").as[Constant].map(Econst)
      case "Eunop"   => 
        for {
          op <- cursor.downField("op").as[String]
          arg <- cursor.downField("arg").as[Expr]
        } yield Eunop(op, arg)
      case "Ebinop"  =>
        for {
          op <- cursor.downField("op").as[String]
          arg1 <- cursor.downField("arg1").as[Expr]
          arg2 <- cursor.downField("arg2").as[Expr]
        } yield Ebinop(op, arg1, arg2)
      case "Eload"   =>
        for {
          chunk <- cursor.downField("chunk").as[String]
          addr <- cursor.downField("addr").as[Expr]
        } yield Eload(chunk, addr)
      case other => Left(DecodingFailure(s"Unknown expr_type: $other", cursor.history))
    }
  }

  // --- Signatures ---
  case class Signature(args: List[String], res: String)
  implicit val signatureDecoder: Decoder[Signature] = deriveDecoder

  // --- Statements ---
  sealed trait Stmt
  case object Sskip extends Stmt
  case class Sset(id: String, expr: Expr) extends Stmt
  case class Sstore(chunk: String, addr: Expr, expr: Expr) extends Stmt
  case class Scall(optid: Option[String], sig: Signature, func: Expr, args: List[Expr]) extends Stmt
  case class Sbuiltin(optid: Option[String], ef: String, args: List[Expr]) extends Stmt
  case class Sseq(s1: Stmt, s2: Stmt) extends Stmt
  case class Sifthenelse(cond: Expr, s1: Stmt, s2: Stmt) extends Stmt
  case class Sloop(body: Stmt) extends Stmt
  case class Sblock(body: Stmt) extends Stmt
  case class Sexit(n: Int) extends Stmt
  
  case class LblStmt(case_val: Option[Long], stmt: Stmt)
  implicit val lblStmtDecoder: Decoder[LblStmt] = deriveDecoder

  case class Sswitch(islong: Boolean, expr: Expr, cases: List[LblStmt]) extends Stmt
  case class Sreturn(expr: Option[Expr]) extends Stmt
  case class Slabel(label: String, stmt: Stmt) extends Stmt
  case class Sgoto(label: String) extends Stmt

  implicit val stmtDecoder: Decoder[Stmt] = Decoder.instance { cursor =>
    cursor.downField("stmt_type").as[String].flatMap {
      case "Sskip" => Right(Sskip)
      case "Sset" =>
        for {
          id <- cursor.downField("id").as[String]
          expr <- cursor.downField("expr").as[Expr]
        } yield Sset(id, expr)
      case "Sstore" =>
        for {
          chunk <- cursor.downField("chunk").as[String]
          addr <- cursor.downField("addr").as[Expr]
          expr <- cursor.downField("expr").as[Expr]
        } yield Sstore(chunk, addr, expr)
      case "Scall" =>
        for {
          optid <- cursor.downField("optid").as[Option[String]]
          sig <- cursor.downField("sig").as[Signature]
          func <- cursor.downField("func").as[Expr]
          args <- cursor.downField("args").as[List[Expr]]
        } yield Scall(optid, sig, func, args)
      case "Sbuiltin" =>
        for {
          optid <- cursor.downField("optid").as[Option[String]]
          ef <- cursor.downField("ef").as[String]
          args <- cursor.downField("args").as[List[Expr]]
        } yield Sbuiltin(optid, ef, args)
      case "Sseq" =>
        for {
          s1 <- cursor.downField("s1").as[Stmt]
          s2 <- cursor.downField("s2").as[Stmt]
        } yield Sseq(s1, s2)
      case "Sifthenelse" =>
        for {
          cond <- cursor.downField("cond").as[Expr]
          s1 <- cursor.downField("s1").as[Stmt]
          s2 <- cursor.downField("s2").as[Stmt]
        } yield Sifthenelse(cond, s1, s2)
      case "Sloop" => cursor.downField("body").as[Stmt].map(Sloop)
      case "Sblock" => cursor.downField("body").as[Stmt].map(Sblock)
      case "Sexit" => cursor.downField("n").as[Int].map(Sexit)
      case "Sswitch" =>
        for {
          islong <- cursor.downField("islong").as[Boolean]
          expr <- cursor.downField("expr").as[Expr]
          cases <- cursor.downField("cases").as[List[LblStmt]]
        } yield Sswitch(islong, expr, cases)
      case "Sreturn" => cursor.downField("expr").as[Option[Expr]].map(Sreturn)
      case "Slabel" =>
        for {
          label <- cursor.downField("label").as[String]
          stmt <- cursor.downField("stmt").as[Stmt]
        } yield Slabel(label, stmt)
      case "Sgoto" => cursor.downField("label").as[String].map(Sgoto)
      case other => Left(DecodingFailure(s"Unknown stmt_type: $other", cursor.history))
    }
  }

  // --- Program Data ---
  case class VarDef(id: String, sz: Long)
  implicit val varDefDecoder: Decoder[VarDef] = Decoder.instance { c =>
    for {
      id <- c.downField("id").as[String]
      szStr <- c.downField("sz").as[String]
    } yield VarDef(id, szStr.toLong)
  }

  case class FunctionDef(
    id: String,
    sig: Signature,
    params: List[String],
    vars: List[VarDef],
    temps: List[String],
    body: Stmt
  )
  implicit val functionDefDecoder: Decoder[FunctionDef] = deriveDecoder

  sealed trait InitData
  case class InitInt8(value: Long) extends InitData
  case class InitInt16(value: Long) extends InitData
  case class InitInt32(value: Long) extends InitData
  case class InitInt64(value: Long) extends InitData
  case class InitFloat32(value: Double) extends InitData
  case class InitFloat64(value: Double) extends InitData
  case class InitSpace(value: Long) extends InitData
  case class InitAddrof(id: String, off: Long) extends InitData

  implicit val initDataDecoder: Decoder[InitData] = Decoder.instance { cursor =>
    cursor.downField("type").as[String].flatMap {
      case "int8" => cursor.downField("val").as[Long].map(InitInt8)
      case "int16" => cursor.downField("val").as[Long].map(InitInt16)
      case "int32" => cursor.downField("val").as[Long].map(InitInt32)
      case "int64" => cursor.downField("val").as[Long].map(InitInt64)
      case "float32" => cursor.downField("val").as[Double].map(InitFloat32)
      case "float64" => cursor.downField("val").as[Double].map(InitFloat64)
      case "space" => cursor.downField("val").as[String].map(v => InitSpace(v.toLong))
      case "addrof" =>
        for {
          id <- cursor.downField("id").as[String]
          off <- cursor.downField("off").as[Long]
        } yield InitAddrof(id, off)
      case other => Left(DecodingFailure(s"Unknown init data type: $other", cursor.history))
    }
  }

  case class GlobVar(readonly: Boolean, volatile: Boolean, init: List[InitData])
  implicit val globVarDecoder: Decoder[GlobVar] = deriveDecoder

  sealed trait GlobDef
  case class InternalFunDef(fun: FunctionDef) extends GlobDef
  case class ExternalFunDef(id: String, ef: String, sig: Signature) extends GlobDef
  case class GlobalVarDef(id: String, `var`: GlobVar) extends GlobDef

  implicit val globDefDecoder: Decoder[GlobDef] = Decoder.instance { cursor =>
    cursor.downField("def_type").as[String].flatMap {
      case "internal_fun" => cursor.downField("fun").as[FunctionDef].map(InternalFunDef)
      case "external_fun" =>
        for {
          id <- cursor.downField("id").as[String]
          ef <- cursor.downField("ef").as[String]
          sig <- cursor.downField("sig").as[Signature]
        } yield ExternalFunDef(id, ef, sig)
      case "var" =>
        for {
          id <- cursor.downField("id").as[String]
          v <- cursor.downField("var").as[GlobVar]
        } yield GlobalVarDef(id, v)
      case other => Left(DecodingFailure(s"Unknown def_type: $other", cursor.history))
    }
  }

  case class Program(main: String, defs: List[GlobDef])
  implicit val programDecoder: Decoder[Program] = deriveDecoder

}
