# The Rating Stone Project

This is a social media web site with an experimental reputation system,
built on top of the training application from [*Ruby on Rails Tutorial:
Learn Web Development with Rails*](https://www.railstutorial.org/)
(6th Edition) by [Michael Hartl](https://www.michaelhartl.com/).

## About Rating Stone

The [Rating Stone web site](https://ratingstone.agmsmith.ca/) lets you
vote up, down or "meh" on all sorts of things (including the usual posts
and pictures).  Find those things easily using our category tree.  Unlike other
systems, we've made it slightly less evil - it forgives the past and avoids
appealing to the addictive side of Human nature.

You can find out more about <em>Rating Stone</em>'s theoretical underpinnings
in the related paper [A Less Dystopian Reputation System](http://web.ncf.ca/au829/WeekendReports/20190201/AGMSReputationSystem.html).
There's also a database design document that is essentially a blueprint for
building the system, [occasionally available in HTML](http://ratingstone.agmsmith.ca/docs/Database%20Design.html)
when the prototype system is running.

## License

The public version of the reputation system is licensed under the GNU General
Public License version 3.  The general idea is that if you improve the code, you
should contribute your changes back to the public.  See [LICENSE.md](LICENSE.md)
for details.  Only changes made after the completion of the tutorial are GPLv3
licensed, the earlier ones are MIT/Beerware licensed.

All source code in the [Ruby on Rails Tutorial](https://www.railstutorial.org/)
is available jointly under the MIT License and the Beerware License.  See
[LICENSE.Hartl.md](LICENSE.Hartl.md) for details.

## Getting started

To get started with the app, clone the repo and then install the needed gems
(assuming Ruby 2.7 and Rails 6.0 are already installed):

```
$ bundle install --without production
$ yarn install --check-files
```

Next, migrate the database:

```
$ rails db:migrate
```

Then compile the assets (CSS style sheets, pictures and other data).

```
$ rails assets:clobber
$ rails assets:precompile
```

Finally, run the test suite to verify that everything is working correctly:

```
$ rails test
```

If the test suite passes, you'll be ready to run the app in a local server:

```
$ rails server
```

For more information, see the
[*Ruby on Rails Tutorial* book](https://www.railstutorial.org/book).
