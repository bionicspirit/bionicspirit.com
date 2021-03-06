---
title: "Tagless Final vs OOP"
date: 2021-01-20 11:24:14+0200
image: /assets/media/snippets/tagless-final-vs-oop.png
tags: 
  - FP
  - OOP
  - Scala
---

These may as well be interview questions for Scala developers:

1. Which signature do you prefer? 
2. Just looking at the signature, what can potentially be wrong with the "tagless final" version?
3. Also discuss the 2 type-class approaches, what are the potential design problems there?

```scala
// -----------------
// Tagless final
def registerUser[F[_]: UserDB: EmailService: Monad](user: User): F[Unit]

// -----------------
// ReaderT (Kleisli) & OOP
def registerUser[F[_]: Monad](
  user: User): Kleisli[F, (UserDB[F], EmailService[F]), Unit]

// -----------------
// Plain function parameters & OOP
def registerUser[F[_]: Monad](
  db: UserDB[F], 
  es: EmailService[F],
  user: User): F[Unit]

// -----------------
// OOP class
final class RegistrationService[F[_]: Monad](
  db: UserDB[F], 
  es: EmailService[F]) {

  def registerUser(user: User): F[Unit]
}

// -----------------
// OOP interface
trait RegistrationService[F[_]] {
  def registerUser(user: User): F[Unit]
}

object RegistrationService {
  def apply[F[_]: Monad](
    db: UserDB[F], 
    es: EmailService[F]): RegistrationService[F] = ???
}

// -----------------
// Type Class (1) — two type params
trait RegistrationService[F[_], Env] {
  def registerUser(env: Env, user: User): F[Unit]
}

object RegistrationService {
  implicit def instance[F[_]: Monad]
    : RegistrationService[F, (UserDB[F], EmailService[F])] = ???
}

// -----------------
// Type Class (2) — single type param
trait RegistrationService[Env[_[_]]] {
  def registerUser[F[_]: Monad](env: Env[F], user: User): F[Unit]
}

object RegistrationService {
  type Env[F[_]] = (UserDB[F], EmailService[F])
  implicit val instance: RegistrationService[Env] = ???
}
```
