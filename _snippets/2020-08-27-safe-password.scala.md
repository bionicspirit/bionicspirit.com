---
image: /assets/media/snippets/safe-password-snippet.png
description: For security, it's not a good practice to keep sensitive data in RAM indefinitely.
tags:
  - JVM
  - Scala
---

See: [Securely Store Sensitive Data in RAM](https://books.nowsecure.com/secure-mobile-development/en/coding-practices/securely-store-sensitive-data-in-ram.html)

```scala
import cats.effect.{ Resource, Sync }
import java.util.ConcurrentModificationException
import java.util.concurrent.atomic.AtomicBoolean

final case class PasswordValue(value: String) {
  override def toString = "PasswordValue(****)"
}

final class SafePassword private (chars: Array[Char]) {
  private[this] val lock = new AtomicBoolean(false)
  private[this] var isAvailable = true

  def read[F[_]](implicit F: Sync[F]): Resource[F, PasswordValue] =
    Resource[F, PasswordValue](F.suspend {
      unsafeAcquire() match {
        case Right(()) =>
          val cancel = F.delay(lock.set(false))
          F.pure((PasswordValue(new String(chars)), cancel))
        case Left(error) =>
          F.raiseError(error)
      }
    })

  def onceThenNullify[F[_]](implicit F: Sync[F]): Resource[F, PasswordValue] =
    read.flatMap { value =>
      Resource(F.pure((value, F.delay(unsafeNullify()))))
    }

  private[this] def unsafeNullify(): Unit = {
    if (isAvailable) {
      isAvailable = false
      for (i <- chars.indices) {
        chars(i) = 0
      }
    }
  }

  private[this] def unsafeAcquire(): Either[Throwable, Unit] =
    if (!lock.compareAndSet(false, true)) {
      Left(
        new ConcurrentModificationException(
          "Cannot use this password from concurrent tasks"
        )
      )
    } else if (!isAvailable) {
      lock.set(false)
      Left(
        new IllegalStateException(
          "Password was nullified already"
        )
      )
    } else {
      Right(())
    }
}

object SafePassword {
  def apply[F[_]](value: String)(implicit F: Sync[F]): F[SafePassword] =
    F.delay(unsafe(value))

  def unsafe(value: String): SafePassword =
    new SafePassword(value.toCharArray)
}
```

And usage:

```scala
SafePassword[IO]("74kDc2J%dd2&").flatMap { pass =>
  pass.onceThenNullify[IO].use { p =>
    IO {
      println(p.value)
    }
  }
}
```
